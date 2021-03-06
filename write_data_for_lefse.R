library(optparse)
library(stringr)

option_list <- list(
    make_option(c("-i", "--input"),metavar="path", dest="otu",help="Paht of abundance table. Required",default=NULL),
    make_option(c("-m", "--map"),metavar="path",dest="map", help="Specify the path of mapping file. Required",default=NULL),
    make_option(c("-c", "--category"),metavar="string",dest="group", help="Categories names seprated by ','. Required",default=NULL),
    make_option(c("-s", "--skip"),metavar="logical",dest="skip", help="T(Skip the first line(e.g. comment line) while reading abundance table) or F(not skip first line)",default=FALSE),
    make_option(c("-u", "--use"),metavar="str",dest="use", help="f(use first column as feature name) or l(use last column as feature name)",default='f'),
    make_option(c("-j", "--modify-feature-name"),metavar="logical",dest="mod", help="T(modify feature name for the use of lefse) or F(modify feature name for the use of huamann2 barplot)",default=TRUE),
    make_option(c("-e", "--is-enzyme"),metavar="logical",dest="isenzyme", help="F(not enzyme) or T(is enzyme)",default=FALSE),
    make_option(c("-n", "--save-colon"),metavar="logical",dest="save_colon", help="F(not save colon) or T(save colon in feature name)",default=FALSE),
    make_option(c("-o", "--output-path"),metavar="path",dest="out", help="Specify the path of output file",default="./data_for_lefse.txt")
    )

opt <- parse_args(OptionParser(option_list=option_list,description = "This script is used to write the input file of LEfSe."))
#if(!dir.exists(opt$out)){dir.create(opt$out,recursive = T)}
outdir=str_replace(opt$out,'[^/]+$','')
if(outdir!=""&!dir.exists(outdir)){dir.create(outdir,recursive = T)}

ag=c(opt$otu,opt$map,opt$group,opt$out,opt$skip,opt$use)


meta<-read.table(ag[2],na.strings="",row.names=1,header = T,sep = "\t",comment.char = "",check.names = F,stringsAsFactors = F)
group<-str_split(ag[3],",")[[1]]

meta<-na.omit(meta[group])

meta<-data.frame(Subject=rownames(meta),meta)

if(as.logical(ag[5])){
	data<-read.table(ag[1],quote="",skip=1,header = T,sep = "\t",comment.char = "",stringsAsFactors = F,check.names = F)
}else{
	data<-read.table(ag[1],quote="",header = T,sep = "\t",comment.char = "",stringsAsFactors = F,check.names = F)
}
#calculate the relative abundance
#data[,2:(ncol(data)-1)]=apply(data[,2:(ncol(data)-1)],2,function(x){x/sum(x)})


data<-data[!data[,1]%in%c("Others", "unclassified"),]


if(ag[6]=='l'){
    data<-data[,c(ncol(data),1:(ncol(data)-1))]
}

if(opt$mod){
    data[,1]<-str_replace(data[,1],"; *[a-z]__ *;.*$","")
    data[,1]<-str_replace(data[,1],"; *[a-z]__ *$","")
    data[,1]<-str_replace(data[,1],";$","")
    data[,1]<-str_replace_all(data[,1],";","|")
}else{
    for(r in c("\\-", "\\(", "\\)", "\\+")){
        data[,1]<-str_replace_all(data[,1], r, "_")
    }
    for(r in c("\\'", '\\"')){
        data[,1]<-str_replace_all(data[,1], r, "")
    }
    if(!opt$save_colon){
        data[,1]<-str_replace_all(data[,1], "\\:", "_")
    }
    # data[,1]<-str_replace_all(data[,1],"\\(","_")
    # data[,1]<-str_replace_all(data[,1],"\\)","_")
    # data[,1]<-str_replace_all(data[,1],"\\+","_")
    # data[,1]<-str_replace_all(data[,1],"\\:","_")
    if(opt$isenzyme){
        data[,1]<-str_replace(data[,1],"\\.","_")
        data[,1]<-str_replace(data[,1],"\\.","_")
        data[,1]<-str_replace(data[,1],"\\.","_")
        data[,1]<-paste('EC', data[,1], sep="")
    }

    
    # data[,1]<-str_replace_all(data[,1]," ","")
    # data[,1]<-str_replace_all(data[,1],'\\"',"")
    # for(i in 1:nrow(data)){
    #     data[i,1]<-ifelse(!is.na(str_extract(data[i,1],"^\\d")), paste('EC',data[i,1], sep=""), data[i,1])
    # }
}

meta<-t(meta)
data<-data[,c(1,match(meta[1,],colnames(data)))]

#Filter otus
#otu_sum<-colSums(t(data[,-1])>0)
#data<-data[otu_sum>0.25*(ncol(data)-1),]

write.table(meta,file = ag[4],row.names = T,col.names = F,quote = F,sep = "\t",append = F)
write.table(data,file = ag[4],row.names = F,col.names = F,quote = F,sep = "\t",append = T)



