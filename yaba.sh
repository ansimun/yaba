#!/bin/bash

# yaba init name backupdir sourcedir1,sourcedir2,...

function help
{
    echo "  yaba set <backupset name> <backuprootdir> <sourcedir1> [<sourcedir2> <sourcedir3> ...]"
    echo "  yaba backup <backupset name>"
    echo "  yaba list"
}

params=($@)
paramCount=${#params[@]}

if [ $paramCount -lt 1 ]; then echo "yaba: invalid param count"; help; exit 1; fi

action=${params[0]}
backupset=${params[1]}

preferencedir="$HOME/.yaba"
backupsetfile="$preferencedir/$backupset"

#----------------------------------------------------------------------------------------
if [ $action = "set" ]; then
    if [ $paramCount -lt 3 ]; then echo "yaba: missing backup root dir"; help; exit 1; fi
    if [ $paramCount -lt 4 ]; then echo "yaba: missing source(s)"; help; exit 1; fi

    if [ ! -d $preferencedir ]; then mkdir $preferencedir; fi
    if [ -f $backupsetfile ]; then rm $backupsetfile; fi

    echo "backuproot=${params[2]}" > $backupsetfile
    
    for (( index=3; index < $paramCount; index++))
    do
	echo "source=${params[$index]}" >> $backupsetfile
    done
#---------------------------------------------------------------------------------------
elif [ $action = "list" ]; then
    backupsets=( `ls -1 $preferencedir` )
    
    for setn in ${backupsets[@]}
    do
	if [ ! -f "$preferencedir/$setn" ]; then continue; fi

	echo "$preferencedir/$setn:"

	sourcedirs=( `grep -E "^source=.*" $preferencedir/$setn | cut -d= -f2` )
	for sourcedir in ${sourcedirs[@]}
	do
	    availability="not available"
	    if [ -d $sourcedir ]; then availability="available"; fi

	    echo "  source=$sourcedir  - $availability"
	done

	backuprootdir=( `grep -E "^backuproot=.*" $preferencedir/$setn | cut -d= -f2` )
	if [ -d $backuprootdir ]; then echo "  backuproot=$backuprootdir  -  available"
	else echo "  backuprootdir  -  not available"; fi
	
	backupdir="$backuprootdir/$setn"
	if [ -d $backupdir ]; then echo "  backupdir=$backupdir  -  available"
	else echo "  backupdir=$backupdir  -  not available"; continue; fi

	backups=( `ls -1 $backuprootdir/$setn` );
	for a in ${backups[@]}
	do
	    echo "  backup: $a"
	done
    done
#----------------------------------------------------------------------------------------
elif [ $action = "backup" ]; then
    if [ ! -f $backupsetfile ]; then 
	echo "yaba: backupset '$backupset' not found, call 'yaba set ...' first"; 
	help; 
	exit 1; 
    fi
    
    backuprootdir=( `grep -E "^backuproot=.*" $backupsetfile | cut -d= -f2` )
    if [ ! $backuprootdir ]; then echo "yaba: no backup root dir specified"; exit 1; fi
    if [ ${#backuprootdir[@]} -gt 1 ]; then echo "yaba: more than one backup root dir specified"; exit 1; fi
    if [ ! -d $backuprootdir ]; then echo "yaba: specified backup root dir is not existing"; exit 1; fi

    sourcedirs=( `grep -E "^source=.*" $backupsetfile | cut -d= -f2` )
    sourcedirCount=${#sourcedirs[@]}
    if [ $sourcedirCount = 0 ]; then echo "yaba: no sources specified"; exit 1; fi

    backupsetdir="$backuprootdir/$backupset";
    if [ ! -d $backupsetdir ]; then mkdir $backupsetdir; fi

    locallinkdir=`ls -tp1 $backupsetdir | grep -E ".*/$" | cut -d "/" -f 1 | head -1`
    linkdir="$backupsetdir/$locallinkdir"

    syncdir="$backupsetdir/`date +%Y-%m-%d`(`date +%H:%M:%S`)"
    if [ -d $syncdir ]; then echo "yaba: backup already exists"; exit 1;
    else mkdir -p $syncdir
    fi

    for source in ${sourcedirs[@]}
    do
	if [ ! -d $source ]; then echo "yaba: source '$source' not found - skip"; continue; fi

	rsync -av --delete --link-dest=$linkdir $source $syncdir
    done
fi
#----------------------------------------------------------------------------------------
