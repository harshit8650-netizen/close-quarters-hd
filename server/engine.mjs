import {readFileSync} from 'node:fs';
export const maps=JSON.parse(readFileSync(new URL('../game/assets/maps.json',import.meta.url),'utf8'));
export const weapons=[
 {name:'AK-47',damage:24,range:29,delay:.16,mag:30,reserve:120},
 {name:'Desert Eagle',damage:42,range:22,delay:.42,mag:7,reserve:35},
 {name:'Shotgun',damage:65,range:9,delay:.8,mag:6,reserve:30},
 {name:'Sniper',damage:85,range:45,delay:1.25,mag:5,reserve:20},
 {name:'Rocket Launcher',damage:80,range:22,delay:1.5,mag:1,reserve:5,radius:4.5},
 {name:'Grenades',damage:65,range:12,delay:1.2,mag:1,reserve:4,radius:4.5,fuse:2},
 {name:'Grenade Launcher',damage:60,range:18,delay:1,mag:4,reserve:12,radius:4,fuse:.65},
 {name:'Smoke Grenade',damage:0,range:12,delay:1.2,mag:1,reserve:3,radius:4,fuse:1.4,kind:'smoke'},
 {name:'Flashbang',damage:0,range:12,delay:1.2,mag:1,reserve:3,radius:7,fuse:1.4,kind:'flash'}];
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const dist=(a,b)=>Math.hypot(a.x-b.x,a.z-b.z);
const finite=(x,d=0)=>typeof x==='number'&&Number.isFinite(x)?x:d;
export function blocked(map,x,z,r=.35){return Math.abs(x)>19.45-r||Math.abs(z)>19.45-r||map.boxes.some(b=>Math.abs(x-b.x)<b.w/2+r&&Math.abs(z-b.z)<b.d/2+r)}
export function lineClear(map,a,b){let d=dist(a,b);for(let s=.15;s<d-.1;s+=.15){let t=s/d;if(blocked(map,a.x+(b.x-a.x)*t,a.z+(b.z-a.z)*t,.02))return false;}return true;}
export function newPlayer(id,name,skin){return {id,name,skin, x:0,z:0,yaw:0,pitch:0,hp:100,kills:0,damage:0,alive:true,weapon:0,ammo:weapons.map(w=>w.mag),reserve:weapons.map(w=>w.reserve),cooldown:0,reload:0,flash:0,seq:0,inputAge:0,input:{},connected:true};}
export class Room{
 constructor(code,mapIndex){this.code=code;this.mapIndex=mapIndex;this.map=maps[mapIndex];this.players=[];this.phase='lobby';this.elapsed=0;this.zone=20;this.effects=[];this.events=[];this.winner=null;this.host=null;}
 add(p){if(this.phase!=='lobby'||this.players.length>=4)return false;this.players.push(p);this.host??=p.id;return true;}
 start(id){if(this.phase!=='lobby'||this.host!==id||this.players.length<2)return false;this.players.forEach((p,i)=>{[p.x,p.z]=this.map.spawns[i];p.yaw=Math.atan2(p.x,p.z);});this.phase='match';return true;}
 input(id,m){const p=this.players.find(p=>p.id===id);if(!p||!p.alive||this.phase!=='match')return;const w=clamp(Math.trunc(finite(m.weapon,p.weapon)),0,weapons.length-1);if(w!==p.weapon){p.weapon=w;p.reload=0;}p.yaw=finite(m.yaw,p.yaw)%(Math.PI*2);p.pitch=clamp(finite(m.pitch),-1.2,1.2);p.inputAge=0;p.input={x:clamp(finite(m.x),-1,1),z:clamp(finite(m.z),-1,1),fire:m.fire===true,reload:m.reload===true};}
 hurt(p,damage,by){if(!p.alive)return;let actual=Math.min(p.hp,damage);p.hp=Math.max(0,p.hp-damage);if(by&&by!==p)by.damage+=actual;if(p.hp<=0){p.alive=false;if(by&&by!==p)by.kills++;this.events.push({kind:'elimination',name:p.name,by:by?.name??'Zone'});}}
 shoot(p){let w=weapons[p.weapon];if(p.reload||p.cooldown>0||p.ammo[p.weapon]<=0)return;p.ammo[p.weapon]--;p.cooldown=w.delay;let dx=-Math.sin(p.yaw),dz=-Math.cos(p.yaw),end={x:p.x,z:p.z}, target=null;let range=w.range*Math.max(.1,Math.cos(p.pitch));for(let s=.15;s<=range;s+=.15){let x=p.x+dx*s,z=p.z+dz*s;if(blocked(this.map,x,z,.03))break;end={x,z};if(!w.radius){target=this.players.find(q=>q!==p&&q.alive&&Math.hypot(q.x-x,q.z-z)<.55&&Math.abs(Math.tan(p.pitch)*s)<.85);if(target)break;}}
 this.events.push({kind:'shot',id:p.id,weapon:p.weapon,x:end.x,z:end.z});if(w.radius){this.effects.push({x:end.x,z:end.z,owner:p.id,weapon:p.weapon,time:w.fuse??.1,kind:'pending'});}else if(target){this.hurt(target,w.damage,p);}}
 tick(dt){if(this.phase!=='match')return;this.elapsed+=dt;this.zone=this.elapsed<240?20:Math.max(1,20-(this.elapsed-240)*19/60);for(const p of this.players){if(!p.alive)continue;p.cooldown=Math.max(0,p.cooldown-dt);p.flash=Math.max(0,p.flash-dt);if(p.reload>0){p.reload-=dt;if(p.reload<=0){p.reload=0;let n=Math.min(weapons[p.weapon].mag-p.ammo[p.weapon],p.reserve[p.weapon]);p.ammo[p.weapon]+=n;p.reserve[p.weapon]-=n;}}p.inputAge+=dt;let i=p.inputAge>.7?{}:p.input;let x=i.x??0,z=i.z??0;let norm=Math.max(1,Math.hypot(x,z));x/=norm;z/=norm;let dx=(Math.cos(p.yaw)*x+Math.sin(p.yaw)*z)*4.8*dt,dz=(-Math.sin(p.yaw)*x+Math.cos(p.yaw)*z)*4.8*dt;if(!blocked(this.map,p.x+dx,p.z))p.x+=dx;if(!blocked(this.map,p.x,p.z+dz))p.z+=dz;if(i.reload&&!p.reload&&p.ammo[p.weapon]<weapons[p.weapon].mag&&p.reserve[p.weapon]>0)p.reload=1.35;if(i.fire)this.shoot(p);if(Math.abs(p.x)>this.zone||Math.abs(p.z)>this.zone)this.hurt(p,dt*14,null);}
 for(const e of this.effects){e.time-=dt;if(e.kind!=='pending'||e.time>0)continue;let w=weapons[e.weapon],owner=this.players.find(p=>p.id===e.owner);if(w.kind==='smoke'){e.kind='smoke';e.time=9;continue;}for(const p of this.players){let d=dist(p,e);if(!p.alive||d>w.radius||!lineClear(this.map,e,p))continue;if(w.kind==='flash')p.flash=3;else this.hurt(p,w.damage*(1-d/w.radius*.65),owner);}e.kind='blast';e.time=.4;}
 this.effects=this.effects.filter(e=>e.time>0);let alive=this.players.filter(p=>p.alive);if(alive.length<=1||this.elapsed>=300){this.phase='ended';let ranked=[...alive].sort((a,b)=>b.hp-a.hp||b.kills-a.kills||b.damage-a.damage||a.id.localeCompare(b.id));this.winner=ranked[0]?.id??null;for(const p of alive)if(p.id!==this.winner)p.alive=false;}}
 snapshot(){return {type:'state',code:this.code,map:this.mapIndex,phase:this.phase,host:this.host,remaining:Math.max(0,Math.ceil(300-this.elapsed)),zone:this.zone,winner:this.winner,players:this.players.map(({input,cooldown,...p})=>p),effects:this.effects,events:this.events.splice(0)};}
}
