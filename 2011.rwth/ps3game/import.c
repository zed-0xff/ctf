#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <sys/mman.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>

#include <sys/ptrace.h>
#include <sys/wait.h>

#ifdef _DEBUG
#define MESSAGE(fmt, ...) printf("\033[32ml%03u  \033[33m%22s  \033[0m" fmt "\n", \
		__LINE__, __FUNCTION__, ##__VA_ARGS__)
#else
#define MESSAGE(fmt, ...) 
#endif

#define ERROR(prefix) MESSAGE(prefix ": %s", strerror(errno))

static size_t g_page_size;

static int g_sock;
static struct sockaddr_in g_remote_addr;

static int GEOWITCH_start_tracer(void * gamearea)
{
	pid_t tracee;
	int status;

	if((tracee = fork()) < 0)
		return (int) tracee;

	if(!tracee)
	{
		ptrace(PTRACE_TRACEME, 0, 0);
		return 0;
	}

	MESSAGE("Tracing payload child process %i", tracee);

	for(;;)
	{
		siginfo_t sig;

		if(waitpid(tracee, &status, 0) < 0)
			break;

		if(ptrace(PTRACE_GETSIGINFO, tracee, 0, &sig) < 0)
		{
			ERROR("Could not copy tracee signal");
			break;
		}

		if(sig.si_signo == SIGALRM)
		{
			MESSAGE("Tracee payload execution timeout occured, killing it");
			ptrace(PTRACE_KILL, tracee, 0, 0);

			break;
		}

		/* GEOWITCH: at ATL about to fly back to DUS, plane boarding.. no time to finish here lol */

	continue_child:
		if(ptrace(PTRACE_CONT, tracee, 0, 0) < 0)
		{
			if(errno != ESRCH)
				ERROR("Could not resume tracee execution");

			break;
		}
	}

	ptrace(PTRACE_KILL, tracee);

	munmap(gamearea, g_page_size);
	_exit(0);
}


static inline int build_path(char * buffer, size_t buffer_size,
	const char * token)
{
	if(strchr(token, '/'))
		return -1;

	if(snprintf(buffer, buffer_size, "cache/%s", token) == buffer_size)
		return -1;

	return 0;
}


int store_flag(const char * token, const char * flag)
{
	char path[256];
	int fd;

	if(build_path(path, sizeof(path), token) < 0)
		return -1;
	
	MESSAGE("Write flag to %s", path);

	if((fd = open(path, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP)) < 0)
		return -1;

	if(write(fd, flag, 32) < 32)
	{
		close(fd);
		return -1;
	}
	
	close(fd);
	return 32;
}

int retrieve_flag(const char * token, char * flag)
{
	int res;
	char path[256];
	int fd;

	if(build_path(path, sizeof(path), token) < 0)
		return -1;
	
	MESSAGE("Read flag from %s", path);

	if((fd = open(path, O_RDONLY)) < 0)
		return -1;

	res = read(fd, flag, 128);

	close(fd);
	return res;
}

int send_response(char * response, size_t length)
{
	register int res;
	res = sendto(g_sock, response, length, 0, (struct sockaddr *) &g_remote_addr, sizeof(g_remote_addr));
	MESSAGE("Sent response of %u bytes: %i", length, res);
	return res;
}


void timeout(int signum)
{
	_exit(0);
}


static inline void execute_gamepiece(char * gamepiece, size_t gamepiece_length)
{
	char * gamearea = mmap(0, g_page_size, PROT_READ | PROT_WRITE | PROT_EXEC,
		MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	int res;

	if(gamearea == MAP_FAILED)
	{
		ERROR("Could not map payload region");
		return;
	}


	gamearea[0] = 0x90;
	memcpy(&gamearea[1], gamepiece, gamepiece_length);
	memset(&gamearea[gamepiece_length + 1], 0xc3, g_page_size - gamepiece_length - 1);
	
	MESSAGE("Running %x bytes payload in area %p of size %x", gamepiece_length, gamearea, g_page_size);

#if 0
	/* GEOWITCH: i'm curious what code sony sends us, so i'm tracing it here   */
	/*           conveniently, we have the code mapped at the same address now */
	if(GEOWITCH_start_tracer(gamearea) < 0)
	{
		ERROR("Could not start tracer");

		munmap(gamearea, g_page_size);
		return;
	}
#endif

//	alarm(1 << 3);
	res = ((int (*)(void *, void *, void *)) gamearea)(store_flag, retrieve_flag, send_response);
	MESSAGE("Payload code returned gracefully, result: %i", res);
	munmap(gamearea, g_page_size);
}

