
#include "luat_base.h"
#include "luat_log.h"
#include "luat_uart.h"
#include "luat_malloc.h"
#include "printf.h"

#include <stdio.h>

// #include "FreeRTOS.h"
// #include "queue.h"
// #include "task.h"

// typedef struct log_msg {
//     char* buff;
// }log_msg_t;

// static QueueHandle_t xQueue = NULL;

static uint8_t luat_log_uart_port = 0;
static uint8_t luat_log_level_cur = LUAT_LOG_DEBUG;

// void luat_log_thread_task(void* args) {
//     log_msg_t msg = {0};
//     while (1) {
//         if (pdTRUE == xQueueReceive(xQueue, &msg, -1)) {
//             printf("%s", msg.buff);
//             luat_heap_free(msg.buff);  
//         };
//     }
// }

// void luat_log_init_win32(void) {
//     xQueue = xQueueCreate(1024, sizeof(void*));
//     xTaskCreate( luat_log_thread_task, "log", 1024*2, NULL, 23, NULL );
// }

void luat_log_set_uart_port(int port) {
    luat_log_uart_port = port;
}

void luat_print(const char* _str) {
    luat_nprint((char*)_str, strlen(_str));
}

void luat_nprint(char *s, size_t l) {
    //luat_uart_write(luat_log_uart_port, s, l);
// #if LUAT_USE_LOG_ASYNC_THREAD
    // char* buff = luat_heap_malloc(l + 1);
    // if (buff == NULL)
    //     return;
    // memcpy(buff, s, l);
    // buff[l] = 0x00;
    // log_msg_t msg = {
    //     .buff = buff
    // };
    // xQueueSendFromISR(xQueue, &msg, NULL);
// #else
    printf("%.*s", l, s);
// #endif
}

void luat_log_set_level(int level) {
    luat_log_level_cur = level;
}
int luat_log_get_level() {
    return luat_log_level_cur;
}
#define LOGLOG_SIZE 1024
void luat_log_log(int level, const char* tag, const char* _fmt, ...) {
    if (luat_log_level_cur > level) return;
    char buff[LOGLOG_SIZE] = {0};
    char *tmp = (char *)buff;
    switch (level)
        {
        case LUAT_LOG_DEBUG:
            buff[0] = 'D';
            break;
        case LUAT_LOG_INFO:
            buff[0] = 'I';
            break;
        case LUAT_LOG_WARN:
            buff[0] = 'W';
            break;
        case LUAT_LOG_ERROR:
            buff[0] = 'E';
            break;
        default:
            buff[0] = '?';
            break;
        }
    buff[1] = '/';
    tmp += 2;
    memcpy(tmp, tag, strlen(tag));
    buff[2+strlen(tag)] = ' ';
    tmp += strlen(tag) + 1;

    va_list args;
    va_start(args, _fmt);
    size_t len = vsnprintf_(tmp, LOGLOG_SIZE, _fmt, args);
    va_end(args);
    if (len > 0) {
        len = strlen(buff);
        // if (len > LOGLOG_SIZE - 2)
        //     len = LOGLOG_SIZE - 2;
        // buff[len] = '\r';
        // buff[len+1] = '\n';
        // luat_nprint(buff, len+2);
        if (len > LOGLOG_SIZE - 1)
            len = LOGLOG_SIZE - 1;
        buff[len] = '\n';
        luat_nprint(buff, len+1);
    }
}
