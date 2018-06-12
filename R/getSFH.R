getSFH=function(mocksurvey='mocksurvey.hdf5', path_shark='.', cores=4, snapmax=199){

  BC03lr=Dale_Msol=Nid=id_galaxy_sam=idlist=snapshot=subsnapID=subsnapshot=z=i=mocksubsets=mockcone=Ntime=time=NULL

  timestart=proc.time()[3]

  SFH=h5file(paste(path_shark,snapmax,'0/star_formation_histories.hdf5', sep='/'), mode='r')
  time=SFH[['age_mean']][]*1e9
  Ntime=SFH[['age_mean']]$dims
  SFH$close()

  mocksurvey=h5file(mocksurvey, mode='r')[['Galaxies']]

  extract_col=list.datasets(mocksurvey, recursive = TRUE)
  mockcone=as.data.table(lapply(extract_col, function(x) mocksurvey[[x]][]))
  colnames(mockcone)=extract_col
  mocksurvey$close()

  mockcone[,subsnapID:=snapshot*100+subsnapshot]
  mocksubsets=mockcone[,list(idlist=list(unique(id_galaxy_sam))),by=subsnapID]
  mocksubsets[,Nid:=length(unlist(idlist)),by=subsnapID]
  mocksubsets[,snapshot:=floor(subsnapID/100)]
  mocksubsets[,subsnapshot:=subsnapID%%100]

  Nunique=length(unlist(mocksubsets$idlist))

  SFRbulge=matrix(0,Nunique,Ntime)
  SFRdisk=matrix(0,Nunique,Ntime)
  Zbulge=matrix(0,Nunique,Ntime)
  Zdisk=matrix(0,Nunique,Ntime)

  message(paste('Extracting Light Cone SFH -',round(proc.time()[3]-timestart,3),'sec'))

  Nstart=1
  for(i in 1:dim(mocksubsets)[1]){
    if(i%%100==0){message(i,' of ',dim(mocksubsets)[1])}
    Nend=Nstart+mocksubsets[i,Nid]-1
    SFH=h5file(paste0(path_shark,'/',mocksubsets[i,snapshot],'/',mocksubsets[i,subsnapshot],'/star_formation_histories.hdf5'), mode='r')
    Ndim=SFH[['Bulges/StarFormationRateHistories']]$dims[1]
    select=which(SFH[['Galaxies/id_galaxy']][] %in% mocksubsets[i,unlist(idlist)])
    SFRbulge[Nstart:Nend,1:Ndim]=SFH[['Bulges/StarFormationRateHistories']][,select]
    SFRdisk[Nstart:Nend,1:Ndim]=SFH[['Disks/StarFormationRateHistories']][,select]
    Zbulge[Nstart:Nend,1:Ndim]=SFH[['Bulges/MetallicityHistories']][,select]
    Zdisk[Nstart:Nend,1:Ndim]=SFH[['Disks/MetallicityHistories']][,select]
    SFH$close()
    Nstart=Nend+1
  }

  return=list(SFRbulge=SFRbulge, SFRdisk=SFRdisk, Zbulge=Zbulge, Zdisk=Zdisk)

}