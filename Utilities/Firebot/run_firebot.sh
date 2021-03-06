#!/bin/bash
if [ ! -d ~/.fdssmvgit ] ; then
  mkdir ~/.fdssmvgit
fi
running=~/.fdssmvgit/bot_running

CURDIR=`pwd`
reponame=~/FDS-SMVgitclean
if [ "$FDSSMV" != "" ] ; then
  reponame=$FDSSMV
fi
if [ -e .fds_git ]; then
  cd ../..
  reponame=`pwd`
  cd $CURDIR
fi

# checking to see if a queing system is available
QUEUE=firebot
notfound=`qstat -a 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -eq 1 ] ; then
  QUEUE=none
fi



function usage {
echo "Verification and validation testing script for FDS"
echo ""
echo "Options:"
echo "-b - branch_name - run firebot using branch_name [default: $BRANCH]"
echo "-c - clean repo"
echo "-f - force firebot run"
echo "-h - display this message"
if [ "$EMAIL" != "" ]; then
echo "-m email_address [default: $EMAIL]"
else
echo "-m email_address "
fi
echo "-q queue - specify queue [default: $QUEUE]"
echo "-r - repository location [default: $reponame]"
echo "-s - skip matlab and build document stages"
echo "-S host - generate images on host"
echo "-u - update repo"
echo "-U - upload guides (only by user firebot)"
echo "-v - show options used to run firebot"
exit
}

BRANCH=development
botscript=firebot.sh
UPDATEREPO=
CLEANREPO=0
UPDATE=
CLEAN=
RUNFIREBOT=1
UPLOADGUIDES=
SSH=
FORCE=
SKIPMATLAB=
while getopts 'b:cfhm:q:nr:sS:uUv' OPTION
do
case $OPTION  in
  b)
   BRANCH="$OPTARG"
   ;;
  c)
   CLEANREPO=1
   ;;
  f)
   FORCE=1
   ;;
  h)
   usage;
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  n)
   UPDATEREPO=0
   ;;
  r)
   reponame="$OPTARG"
   ;;
  s)
   SKIPMATLAB=-s
   ;;
  S)
   SSH="-S $OPTARG"
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=-U
   ;;
  v)
   RUNFIREBOT=0
   ;;
esac
done
shift $(($OPTIND-1))

if [ -e $running ] ; then
  if [ "$FORCE" == "" ] ; then
    echo Firebot is already running.
    echo Firebot or smokebot are already running.
    echo "Re-run using the -f option if this is not the case."
    exit
  fi
fi
if [[ "$EMAIL" != "" ]]; then
  EMAIL="-m $EMAIL"
fi
if [[ "$UPDATEREPO" == "1" ]]; then
   UPDATE=-u
   cd $reponame
   if [[ "$RUNFIREBOT" == "1" ]]; then
     git remote update &> /dev/null
     git checkout $BRANCH &> /dev/null
     git merge origin/$BRANCH &> /dev/null
     cd Utilities/Firebot
     FIREBOTDIR=`pwd`
     if [[ "$CURDIR" != "$FIREBOTDIR" ]]; then
       cp $botscript $CURDIR/.
     fi
     cd $CURDIR
  fi
fi
if [[ "$CLEANREPO" == "1" ]]; then
  CLEAN=-c
fi
touch $running
BRANCH="-b $BRANCH"
QUEUE="-q $QUEUE"
reponame="-r $reponame"
if [ "$RUNFIREBOT" == "1" ] ; then
  ./$botscript $UPDATE $UPLOADGUIDES $SSH $CLEAN $BRANCH $QUEUE $SKIPMATLAB $reponame $EMAIL "$@"
else
  echo ./$botscript $UPDATE $UPLOADGUIDES $SSH $CLEAN $BRANCH $QUEUE $SKIPMATLAB $reponame $EMAIL "$@"
fi
rm $running
