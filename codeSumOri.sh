#!bin/sh
#author by liuchenwei
#功能：实现自动化统计某段时间内开发人员的代码提交量
#-------------------------------------------------------------------
#Author: CaoZheng
#Date: 2017/11/07
#Modify: 1.简化代码，增强可读性
#        2.由于该脚本生成了临时文件，不能使用多个进程同时执行该脚本。
#          所以使用随机临时目录可以解决这一问题
#-------------------------------------------------------------------

DATE="$1"
NEXT_DATE="$(date -d "+1 day $DATE" +%F)"
SVN_URL="$2"
TMP_DIR="/tmp/$(openssl rand -hex 5)"

mkdir -p $TMP_DIR
cd $TMP_DIR

svn log -r {$DATE}:{$NEXT_DATE} $SVN_URL | grep $DATE | grep -w '|' | grep -v "liuchenwei\|sunbenkang\|chenyannan\|kuangxinwei\|gaoyan\|tianhongsong\|wangweixuan\|caozheng\|ronghanzhong" > temp.txt

cat temp.txt | while read LINE
do
    revision=$(echo $LINE | awk -F "|" '{ print $1 }')
    revision_num=$(echo ${revision:1}) 
    name=$(echo $LINE | awk -F "|" '{ print $2 }')

    svn diff -r $[$revision_num-1]:$revision_num $SVN_URL  --username liuchenwei --password liuchenwei >  svncodelines.txt
  
    add_lines_num=$(grep "^+" svncodelines.txt | grep -v "^+++" | sed '/^$/d' | wc -l)
    if [ $add_lines_num -gt 1000 ];then
        add_lines_num=0
    fi

    del_lines_num=$(grep "^-" svncodelines.txt | grep -v "^---" | sed '/^$/d' | wc -l)
    if [ $del_lines_num -gt 1000 ];then
        del_lines_num=0
    fi

    echo $add_lines_num $name >> a
done

awk 'NR==FNR{a[$2]+=$1}NR!=FNR&&++b[$2]==1{print $2,a[$2]}' a a > sum.txt 2>/dev/null

# transfer account to Chinese name
sed -i 's#zhaojunfeng#赵#' sum.txt
sed -i 's#chengzhou#成#' sum.txt
sed -i 's#chengwenliang#程#' sum.txt
sed -i 's#huyule#胡#' sum.txt
sed -i 's#zhengyiwen#郑#' sum.txt
sed -i 's#yangning2 #杨#' sum.txt
sed -i 's#tangsan#唐#' sum.txt
sed -i 's#shizhouqi#施#' sum.txt
sed -i 's#lina#李#' sum.txt
sed -i 's#biewanwen#别#' sum.txt
sed -i 's#zhangfeifan#张#' sum.txt
sed -i 's#xiongwanqiang#熊#' sum.txt
sed -i 's#zonghanzhong_zh#戎#' sum.txt
sed -i 's#wanwenjuan#万#' sum.txt
sed -i 's#xingyongguang#邢#' sum.txt
sed -i 's#boyifan_xp#薄#' sum.txt
sed -i 's#hejintao_xp#何#' sum.txt
sed -i 's#huanghong#黄#' sum.txt
sed -i 's#huiwenhua#惠华#' sum.txt
sed -i 's#xiejingjing_xp#晶#' sum.txt
sed -i 's#zhangge#章#' sum.txt
sed -i 's#huangzhen#黄#' sum.txt
sed -i 's#guohai.shan#国海#' sum.txt
sed -i 's#shihaojun#浩军#' sum.txt
sed -i 's#wanghongtao#虹涛#' sum.txt
sed -i 's#caopeipei#培培#' sum.txt
sed -i 's#xulingjie_lt#凌杰#' sum.txt
sed -i 's#guoqin#琴#' sum.txt
sed -i 's#zhufangyuan#方远#' sum.txt
sed -i 's#tanxiaoying#潇莹#' sum.txt
sed -i 's#jiaxinyue#昕越#' sum.txt
sed -i 's#liubing#冰#' sum.txt
sed -i 's#duqiang#杜#' sum.txt
sed -i 's#zhaochi#池#' sum.txt
sed -i 's#yangchong#冲#' sum.txt
sed -i 's#zhufeiran#朱斐#' sum.txt
sed -i 's#shenjiajia#沈佳#' sum.txt
sed -i 's#wanghongxu#忠旭#' sum.txt
sed -i 's#suhongli#红莉#' sum.txt
sed -i 's#yuanxianhui#袁慧#' sum.txt
sed -i 's#lipiao#李#' sum.txt
sed -i 's#xieye#谢#' sum.txt
sed -i 's#fangjian_zr#方#' sum.txt
sed -i 's#jiangjiamin_zr#江敏#' sum.txt
sed -i 's#liuyong_zr#勇#' sum.txt
sed -i 's#caoshuangwei_zr#双伟#' sum.txt
sed -i 's#lisongze#松泽#' sum.txt
sed -i 's#baifan_xz#白#' sum.txt
sed -i 's#jiangzhifang_xz#芳#' sum.txt
sed -i 's#jiyingcai_xz#季财#' sum.txt
sed -i 's#yubin_xz#于#' sum.txt
sed -i 's#baixiangxu_xz#祥旭#' sum.txt
sed -i 's#lipeng_xz#李#' sum.txt
sed -i 's#tangliang#汤#' sum.txt
sed -i 's#peixuelong#学龙#' sum.txt
sed -i 's#dengxiangying#英#' sum.txt
sed -i 's#sunliwen_yt#丽#' sum.txt
sed -i 's#huangxueshan_yt#黄学#' sum.txt
sed -i 's#gaofen_yt#高#' sum.txt
sed -i 's#zhangyanan_yt#亚男#' sum.txt
sed -i 's#caoyuqin_yt#琴#' sum.txt
sed -i 's#zhangjia_hut#佳' sum.txt
sed -i 's#lizhanfeng_ht#占锋#' sum.txt
sed -i 's#jishengwei_hut#胜伟#' sum.txt
sed -i 's#wangmingdi_hut#明迪#' sum.txt
sed -i 's#zhouyingchun_hut#迎春#' sum.txt
sed -i 's#wangyang_hut#阳#' sum.txt
sed -i 's#wangzhongxu#忠旭#' sum.txt
sed -i 's#caozhili_lt#指利#' sum.txt
sed -i 's#lifei_xz#飞#' sum.txt
sed -i 's#yangjiwei_xz#伟#' sum.txt



cat sum.txt

rm -rf  $TMP_DIR
