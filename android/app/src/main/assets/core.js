(() => {
  'use strict';

  const VERSION='0.5.0';
  const DATA_KEY='smartATSPro.data';
  const BACKUP_KEYS=['smartATSPro.autoBackup.1','smartATSPro.autoBackup.2','smartATSPro.autoBackup.3'];
  const originalSetItem=Storage.prototype.setItem;
  let lastBackupAt=0;

  function safeParse(raw){try{return JSON.parse(raw);}catch(e){return null;}}
  function shouldBackup(){return Date.now()-lastBackupAt>15000;}
  function rotateBackup(storage,current){
    if(!current||!shouldBackup())return;
    lastBackupAt=Date.now();
    const b1=storage.getItem(BACKUP_KEYS[0]);
    const b2=storage.getItem(BACKUP_KEYS[1]);
    if(b2) originalSetItem.call(storage,BACKUP_KEYS[2],b2);
    if(b1) originalSetItem.call(storage,BACKUP_KEYS[1],b1);
    originalSetItem.call(storage,BACKUP_KEYS[0],current);
  }

  Storage.prototype.setItem=function(key,value){
    if(key===DATA_KEY){
      const parsed=safeParse(String(value));
      if(parsed&&Array.isArray(parsed.jobs)&&Array.isArray(parsed.candidates)){
        rotateBackup(this,this.getItem(DATA_KEY));
        parsed.version=VERSION;
        parsed.updatedAt=new Date().toISOString();
        return originalSetItem.call(this,key,JSON.stringify(parsed));
      }
    }
    return originalSetItem.call(this,key,value);
  };

  function migrateNow(){
    const current=safeParse(localStorage.getItem(DATA_KEY));
    if(!current||!Array.isArray(current.jobs)||!Array.isArray(current.candidates))return;
    if(current.version!==VERSION){current.version=VERSION;current.updatedAt=new Date().toISOString();originalSetItem.call(localStorage,DATA_KEY,JSON.stringify(current));}
  }

  function restoreLatestBackup(){
    for(const key of BACKUP_KEYS){
      const raw=localStorage.getItem(key);const parsed=safeParse(raw);
      if(parsed&&Array.isArray(parsed.jobs)&&Array.isArray(parsed.candidates)){
        originalSetItem.call(localStorage,DATA_KEY,JSON.stringify({...parsed,version:VERSION,updatedAt:new Date().toISOString()}));
        location.reload();return true;
      }
    }
    return false;
  }

  window.SmartATSBuild={version:VERSION,restoreLatestBackup,backupKeys:[...BACKUP_KEYS]};
  migrateNow();
})();
