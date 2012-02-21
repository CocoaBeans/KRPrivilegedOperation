#import "recvfdpriv.h"
#import <sys/socket.h>		/* struct msghdr */
#import <sys/un.h>

/* RFC 2292 additions */
#define	CMSG_SPACE(l)		(__DARWIN_ALIGN32(sizeof(struct cmsghdr)) + __DARWIN_ALIGN32(l))
#define	CMSG_LEN(l)		(__DARWIN_ALIGN32(sizeof(struct cmsghdr)) + (l))


#define	SCM_TIMESTAMP	0x02		/* timestamp (struct timeval) */
#define	SCM_CREDS	0x03		/* process creds (struct cmsgcred) */

#define LOCAL_PEERCRED          0x001           /* retrieve peer credentails */

/*
 * While we may have more groups than this, the cmsgcred struct must
 * be able to fit in an mbuf, and NGROUPS_MAX is too large to allow
 * this.
 */
#define CMGROUP_MAX 16

/*
 * Credentials structure, used to verify the identity of a peer
 * process that has sent us a message. This is allocated by the
 * peer process but filled in by the kernel. This prevents the
 * peer from lying about its identity. (Note that cmcred_groups[0]
 * is the effective GID.)
 */
struct cmsgcred {
	pid_t	cmcred_pid;		/* PID of sending process */
	uid_t	cmcred_uid;		/* real UID of sending process */
	uid_t	cmcred_euid;		/* effective UID of sending process */
	gid_t	cmcred_gid;		/* real GID of sending process */
	int16_t	cmcred_ngroups;		/* number or groups */
	gid_t	cmcred_groups[CMGROUP_MAX];	/* groups */
};


#if defined(SCM_CREDS)			/* BSD interface */
#define CREDSTRUCT		cmsgcred
#define CR_UID			cmcred_uid
#define CREDOPT			LOCAL_PEERCRED
#define SCM_CREDTYPE	SCM_CREDS
#elif defined(SCM_CREDENTIALS)	/* Linux interface */
#define CREDSTRUCT		ucred
#define CR_UID			uid
#define CREDOPT			SO_PASSCRED
#define SCM_CREDTYPE	SCM_CREDENTIALS
#else
#error passing credentials is unsupported!
#endif

/* size of control buffer to send/recv one file descriptor */
#define RIGHTSLEN	CMSG_LEN(sizeof(int32_t))
#define CREDSLEN	CMSG_LEN(sizeof(struct CREDSTRUCT))
#define	CONTROLLEN	(RIGHTSLEN + CREDSLEN)

static struct cmsghdr	*cmptr = NULL;		/* malloc'ed first time */

/*
 * Receive a file descriptor from a server process.  Also, any data
 * received is passed to (*userfunc)(STDERR_FILENO, buf, nbytes).
 * We have a 2-byte protocol for receiving the fd from send_fd().
 * This code is from "Passing File Descriptors",
 * Advanced Programming in the UNIX Environment by W. Richard Stevens
 */
int
recv_ufd(int32_t fd, uid_t *uidptr,
        ssize_t (*userfunc)(int32_t fd, const void *ptr, size_t size))
{
	struct cmsghdr		*cmsghdrPtr;
	struct CREDSTRUCT	*credPtr;
	int32_t             newfd, nr, status;
	char				*ptr;
	char				buf[MAXLINE];
	struct iovec		iov[1];
	struct msghdr		message;
	const int32_t       on = 1;

	status = -1;
	newfd = -1;
	if (setsockopt(fd, SOL_SOCKET, CREDOPT, &on, sizeof(int)) < 0) {
		err_ret("setsockopt failed");
		return(-1);
	}
	for ( ; ; ) {
		iov[0].iov_base = buf;
		iov[0].iov_len  = sizeof(buf);
		message.msg_iov     = iov;
		message.msg_iovlen  = 1;
		message.msg_name    = NULL;
		message.msg_namelen = 0;
		if (cmptr == NULL && (cmptr = malloc(CONTROLLEN)) == NULL)
			return(-1);
		message.msg_control    = cmptr;
		message.msg_controllen = CONTROLLEN;
        
		if ((nr = (int32_t)recvmsg(fd, &message, 0)) < 0) {
			err_sys("recvmsg error");
		} else if (nr == 0) {
			err_ret("connection closed by server");
			return(-1);
		}

		/*
		 * See if this is the final data with null & status.  Null
		 * is next to last byte of buffer; status byte is last byte.
		 * Zero status means there is a file descriptor to receive.
		 */
		for (ptr = buf; ptr < &buf[nr]; ) {
			if (*ptr++ == 0) {
				if (ptr != &buf[nr-1])
					err_dump("message format error");
 				status = *ptr & 0xFF;	/* prevent sign extension */
 				if (status == 0) {
#ifdef DEBUG
					if (message.msg_controllen != CONTROLLEN)
                    {
//						err_dump("status = 0 but no fd");
                        printf("recv_ufd: expected msg.msg_controllen == %lu but is %d instead.\n", CONTROLLEN, message.msg_controllen);
                        fflush(stdout);
                    }   
#endif
					/* process the control data */
					for (cmsghdrPtr = CMSG_FIRSTHDR(&message);
					  cmsghdrPtr != NULL; cmsghdrPtr = CMSG_NXTHDR(&message, cmsghdrPtr)) {
						if (cmsghdrPtr->cmsg_level != SOL_SOCKET)
							continue;
						switch (cmsghdrPtr->cmsg_type) {
						case SCM_RIGHTS:
							newfd = *(int32_t*)CMSG_DATA(cmsghdrPtr);
							break;
						case SCM_CREDTYPE:
							credPtr = (struct CREDSTRUCT *)CMSG_DATA(cmsghdrPtr);
							*uidptr = credPtr->CR_UID;
                        break;
						}
					}
				} else {
					newfd = -status;
				}
				nr -= 2;
			}
		}
        int eval = ( (nr > 0) && (*userfunc)(STDERR_FILENO, buf, nr));
		if (eval != nr)
			return(-1);
		if (status >= 0)	/* final data has arrived */
			return(newfd);	/* descriptor, or -status */
	}
}
