#!/bin/bash
SrcDir="/usr/local/jenkins/workspace/php-rollback"
DeployCode="/deploy/tmp"
DstDir="/opt/wwwroot"
WebSite="/web/"
PRONAME="php-rollback"
if [ $# == 1 ];then
Ver_NUM=$(echo $1)
cd $SrcDir
	if [ ${Ver_NUM} == 'latest' ];then
		#版本回退到上一个版本
		git reset --hard HEAD^
		COMMITID="$(git rev-parse --short HEAD)"
		#ssh www@10.2.11.245 "rm -rf /web/${PRONAME} && ln -s /opt/wwwroot/${PRONAME}-${COMMITID} /web/${PRONAME}"
		ssh -p27037 root@127.0.0.1 "rm -rf /web/${PRONAME} && ln -s /opt/wwwroot/${PRONAME}-${COMMITID} /web/${PRONAME}"
	else
		#版本回退到任意版本，请输入版本COMMITID
		git reset --hard ${Ver_NUM}
		#ssh www@10.2.11.245 "rm -rf /web/${PRONAME} && ln -s /opt/wwwroot/${PRONAME}-${Ver_NUM} /web/${PRONAME}"
		ssh -p27037 root@127.0.0.1 "rm -rf /web/${PRONAME} && ln -s /opt/wwwroot/${PRONAME}-${Ver_NUM} /web/${PRONAME}"
	fi
else
	cd $SrcDir && git pull origin master
	COMMITID="$(git rev-parse --short HEAD)"
	#把版本库里获取的代码，拷贝一份到部署目录里，并且重命名这个项目(按照项目名-commitID号），并且把不要的目录删除掉，比如.git
	PKGNAME="${PRONAME}-${COMMITID}"
	cp -rf ${SrcDir} ${DeployCode}/ && cd ${DeployCode} && mv ${PRONAME} ${PKGNAME}
	cd ${DeployCode}/${PKGNAME} && rm -rf .git
	cd ${DeployCode} && tar zcf ${PKGNAME}.tar.gz ${PKGNAME}
	#通过scp命令，把对应的目录拷贝到远程计算机中
	scp -r -P27037 ${DeployCode}/${PKGNAME}.tar.gz root@127.0.0.1:${DstDir}/
	#ssh www@10.2.11.245 "cd ${DstDir} && tar xf ${PKGNAME}.tar.gz"
	ssh -p27037 root@127.0.0.1 "cd ${DstDir} && tar xf ${PKGNAME}.tar.gz"
	#通过ssh远程连接到10.2.11.245服务器，创建软连接
	ssh -p27037 root@127.0.0.1 "rm -rf /web/${PRONAME} && ln -s /opt/wwwroot/${PKGNAME} /web/${PRONAME}"
fi
