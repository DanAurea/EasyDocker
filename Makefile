# Image's / Container's name
IMG=web
CTN=nginx

# Image / Container status
RUNNING=$(shell docker ps | tr -s " " ":" | grep $(CTN) | wc -l)
ECTN=$(shell docker ps -a | tr -s " " ":" | grep $(CTN) | wc -l )
EIMG=$(shell docker images | tr -s " " ":" | grep $(IMG) | wc -l)
ELOG=$(shell ls -l | grep Docker_$(CTN).log | wc -l)

# Sharing options
SHARE=
CPU=160
CPUCORES=
MEM=1360
MEMS=
# Memory unit
MEMU=M

# Working directory
WD=~/Documents/Server/data/web

# Docker flags
SFLAGS=-i
RFLAGS=-it
BFLAGS=-t
CFLAGS=
BDIR=

# Docker mounted volumes
VOLUMES=/conf/nginx.conf:/etc/nginx/nginx.conf /www:/var/www /logs:/var/log/nginx
MOUNT=$(addprefix -v $(WD), $(VOLUMES))

# Docker bound ports
PORTS=80:80 443:443
PUBLISH=$(addprefix -p=, $(PORTS))

#Errors
NFCTN="Container $(CTN) not found"
NFIMG="Image $(IMG) not found"

# Add default exec's flags if not defined when make exec
ifndef FEXEC
	FEXEC=-it
endif

# Add default command flags if not defined when make exec
ifndef CMD
	CMD=/bin/bash
endif

# Set building directory, default is working directory
ifeq ($(BDIR),)
	BDIR+=.
endif

# Set sharing options
ifeq ($(SHARE),)

	# Add CPU usage option to container building rule
	ifneq ($(CPU),)
		SHARE+=--cpu-shares=$(CPU)
	endif

	# Set memory unit for next steps
	ifeq ($(MEMU),)
		MEMU+=M
	endif

	# Add memory usage option to container building rule, default unit is Mo
	ifneq ($(MEM),)
		SHARE+=-m $(MEM)$(MEMU)
	endif

	# Add memory swap option to container building rule, default unit is Mo
	ifneq ($(MEMS),)
		SHARE+=--memory-swap $(MEMS)$(MEMU)
	endif

	# Add cpu cores used to container building rule
	ifneq ($(CPUCORES),)
		SHARE+=--cpuset-cpus=$(CPUCORES)
	endif

endif


all: build

# Build image / container for chosen application
build: img ctn

# Inspect informations of container
inspect:
	docker inspect $(CTN)

# Build image for chosen application
img:

	@$(MAKE) del-ctn > /dev/null
	@$(MAKE) del-img > /dev/null

	@echo "Image building currently in progress, wait until the end of process [...]"
	@docker build $(BFLAGS) $(IMG) . > /dev/null
	@echo "Image building finished"

# Delete image
del-img:

	@$(MAKE) del-ctn > /dev/null
ifeq ($(EIMG), 1) # Existing image
	@docker rmi $(IMG) > /dev/null
else
	@echo $(NFIMG) # Error image not found
endif


# Build container for chosen application
ctn:

ifneq ($(EIMG), 1)
	@$(MAKE) img > /dev/null # Build image if not existing
endif
	
	@$(MAKE) del-ctn > /dev/null # Delete existing container with same name

	@echo "\nA container $(CTN) will be created [...]"
	@docker run $(SHARE) $(PUBLISH) $(MOUNT) --name $(CTN) $(RFLAGS) $(IMG) $(CMD) # Build new container
	@echo "Container $(CTN) is now created"

# Delete container
del-ctn:

	@$(MAKE) stop > /dev/null

ifeq ($(ECTN), 1) # Existing container
	@docker rm $(CTN) > /dev/null
else
	@echo $(NFCTN) # Error container not found
endif


# Execute command in container for chosen application
exec:
	docker exec $(FEXEC) $(CTN) $(CMD)

# Reattach container for chosen application
attach:
	docker attach $(CTN)

# Create a log file with docker logs of chosen application
log:
	@docker logs $(CTN) > Docker_$(CTN).log
	@echo "A log file for container $(CTN) has been created in current working directory"

# Remove log file for chosen application
rm-log:

ifeq ($(ELOG), 1)
	@rm Docker_$(CTN).log
endif

# Clean all files bound to chosen application
clean:
	@$(MAKE) rm-log > /dev/null
	@$(MAKE) del-img > /dev/null


# Commit changes on container
commit:

ifeq ($(ECTN), 1)
	@docker commit $(CFLAGS) $(CTN)
else
	@echo $(NFCTN) # Error container not found
endif

# Start container
start:
	
ifneq ($(RUNNING), 1) # Not currently running
ifeq ($(ECTN), 1) # Existing container
	@docker start $(SFLAGS) $(CTN)
else
	@echo $(NFCTN) # Error container not found
endif
endif

# Restart container
restart:

ifeq ($(RUNNING), 1) # Currently running
	@docker restart $(SFLAGS) $(CTN)
endif

# Stop container
stop:

ifeq ($(ECTN), 1) # Existing container
ifeq ($(RUNNING), 1) # Running container
	@docker stop $(CTN) > /dev/null
endif

else
	@echo $(NFCTN) # Error container not found
endif

# Update ressource share
update:

ifeq ($(ECTN), 1) # Existing container
	@docker update $(SHARE) $(CTN)

else
	@echo $(NFCTN) # Error container not found
endif

# Rename image's name
rn-img:

ifeq ($(EIMG), 1) # Existing image
ifdef NAME
	@docker tag $(IMG) $(NAME) # Rename image
	@docker rmi $(IMG) > /dev/null # Delete old tag on image
	@sed -i.bak -e "s/IMG=$(IMG)/IMG=$(NAME)/g" Makefile  # Rename image's name in Makefile to keep working command next time
else
	@echo "common usage: make rn-img NAME=new-name\n\nA new name must be specified to rename image"
endif

else
	@echo $(NFIMG) # Error image not found
endif

# Rename container's name
rn-ctn:

ifeq ($(ECTN), 1) # Existing container
ifdef NAME
	@$(MAKE) stop > /dev/null # Stop container
	@docker rename $(CTN) $(NAME) # Rename container
	@$(MAKE) start > /dev/null # Restart container
	@sed -i.backup -e "s/CTN=$(CTN)/CTN=$(NAME)/g" Makefile  # Rename container's name in Makefile to keep working command next time
else
	@echo "common usage: make rn-ctn NAME=new-name\n\nA new name must be specified to rename container"
endif

else
	@echo $(NFCTN) # Error container not found
endif

# Stats on container
stats:

ifeq ($(ECTN), 1)
	@docker stats $(CTN)
else
	@echo $(NFCTN) # Error container not found
endif

.PHONY: log attach exec ctn img build clean update stop start restart