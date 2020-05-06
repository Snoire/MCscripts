#include <stdio.h>
#include <sys/inotify.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>

#define errExit(msg)    do { perror(msg); exit(EXIT_FAILURE); \
                        } while (0)
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define BUF_LEN  (sizeof(struct inotify_event) + NAME_MAX + 1)

#define LINELEN  150        //最长的一条 log 差不多 80 个字符
#define STR(x)   STR2(x)
#define STR2(x)  #x

time_t pretime = 0;                                  //前一次显示提示语的时间

static char *handleEvent(struct inotify_event *i, const char *file, char *p)
{
    FILE *fp;
    long bytes_count;
    char str[LINELEN+1] = "";
    char player[20] = "";                                //人名最多 15 个字符
    char player_lowercase[20] = "";                                //人名最多 15 个字符
    char cmdstr[32] = "";

    if (time(NULL)-pretime < 60)                         //距离前一次小于一分钟
        return NULL;

    fp = fopen(file, "r");
    if (fp == NULL)
        fprintf(stderr, "open %s error!\n", file);

    fseek(fp, 0L, SEEK_END);
    bytes_count = ftell(fp);
    fseek(fp, -MIN(bytes_count, LINELEN), SEEK_CUR);

//    bytes_count = ftell(fp);

    int ret = 0;
    while (ret != EOF) {
        ret = fscanf(fp, "%"STR(LINELEN)"[^\n]%*c", str);
    }
    printf("lastline: %s\n", str);

    char *p1, *p2;
    p1 = strstr(str, "Player connected: ");  //18 个字符

    if (!p1) {
        if (strstr(str, "You whisper to")) {              // check 
            pretime = time(NULL);
            fclose(fp);
            free(p);
            return NULL;
        } else if (strstr(str, "No targets matched selector")) {
            system(p);
            fclose(fp);
            return p;
        } else {
            fclose(fp);
            return NULL;
        }
    }


    p2 = strstr(p1+18, ",");

    strncpy(player, p1+18, strlen(p1)-strlen(p2)-18);
//    printf("player: %s\n", player);

    for (int i=0; i<=strlen(player); i++) {
        if (player[i]>='A' && player[i]<='Z')
            player_lowercase[i] = player[i]+32;
        else
            player_lowercase[i] = player[i];
    }

//    printf("player_lowercase: %s\n", player_lowercase);
    sprintf(cmdstr, "mc command \"w %s hi %s, welcome!\"", player_lowercase, player);
//    printf("cmdstr: %s\n", cmdstr);
    sleep(8);                            //wait
    system(cmdstr);
    fclose(fp);
    return strdup(cmdstr);
}


int main(int argc, char *argv[])
{
    int inotifyFd, wd, j;
    char buf[BUF_LEN] __attribute__ ((aligned(8)));  //字节对齐，gcc 扩展语法
    ssize_t numRead;
    char *p;

    if (argc < 2 || strcmp(argv[1], "--help") == 0) {
        fprintf(stderr, "Usage: %s pathname...\n", argv[0]);
        exit(-1);
    }

    inotifyFd = inotify_init();                 /* Create inotify instance */
    if (inotifyFd == -1)
        errExit("inotify_init");

    for (j = 1; j < argc; j++) {
        wd = inotify_add_watch(inotifyFd, argv[j], IN_MODIFY);
        if (wd == -1)
            errExit("inotify_add_watch");

//        printf("Watching %s using wd %d\n", argv[j], wd);
    }

//    printf("buf_len: %ld\n", BUF_LEN);

    for (;;) {                                  /* Read events forever */
        numRead = read(inotifyFd, buf, BUF_LEN);
        if (numRead == 0) {
            fprintf(stderr, "read() from inotify fd returned 0!");
            exit(-1);
        }

        if (numRead == -1)
            errExit("read");

//        printf("Read %ld bytes from inotify fd\n", (long) numRead);

        /* Process all of the events in buffer returned by read() */
        p = handleEvent((struct inotify_event *) buf, argv[1], p);
        sleep(4);                            //time between every check

    }

    return 0;
}

