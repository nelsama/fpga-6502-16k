// Receptor HDMI independiente: solo mira los simbolos de 10 bits
const fs=require('fs');const L=fs.readFileSync('q.txt','utf8').trim().split(/\r?\n/);
const C={'1101010100':0,'0010101011':1,'0101010100':2,'1010101011':3};
const T={};['1010011100','1001100011','1011100100','1011100010','0101110001','0100011110','0110001110','0100111100','1011001100','0100111001','0110011100','1011000110','1010001110','1001110001','0101100011','1011000011'].forEach((s,i)=>T[s]=i);
function dec(s){const b=[...s].reverse().map(Number);if(b[9])for(let i=0;i<8;i++)b[i]^=1;let o=b[0];for(let i=1;i<8;i++){let x=b[i]^b[i-1];if(!b[8])x^=1;o|=x<<i}return o}
const S=L.map(l=>l.trim().split(/ +/));const G='0100110011',V='1011001100';
let err={},E=(k,i)=>{err[k]=err[k]||[0,i];err[k][0]++};
let vid=0,vidbad=0,isl=0,pk={},aud=[],i=20,frames=[],maxp=0,ctl=0,minctl=9e9,disp=[0,0,0],maxd=0;
// la salida va 1 ciclo detras de hs/vs/de
const ref=k=>S[k-1];
function bch(bits){let e=0;for(const b of bits){const x=(e&1)^b;e>>=1;if(x)e^=0x83}return e}
function packet(d,at){const hb=d.map(x=>x[0]);const h=hb.slice(0,24);let e=bch(h),r=0;for(let k=0;k<8;k++)r|=hb[24+k]<<k;if(e!=r)E('ecc cabecera',at);
 const B=n=>{let v=0;for(let k=0;k<8;k++)v|=h[n*8+k]<<k;return v};const hd=[B(0),B(1),B(2)];const subs=[];
 for(let s=0;s<4;s++){const b=[];for(const x of d){b.push(x[1]>>s&1,x[2]>>s&1)}let r=0;for(let k=0;k<8;k++)r|=b[56+k]<<k;if(bch(b.slice(0,56))!=r)E('ecc sub',at);const by=[];for(let n=0;n<7;n++){let v=0;for(let k=0;k<8;k++)v|=b[n*8+k]<<k;by.push(v)}subs.push(by)}
 pk[hd[0]]=(pk[hd[0]]||0)+1;
 if(hd[0]==2){const by=subs[0],l=by[0]|by[1]<<8|by[2]<<16,r=by[3]|by[4]<<8|by[5]<<16,f=by[6];const par=x=>{let p=0;while(x){p^=x&1;x>>=1}return p};
  if(par(l)^par(f&15))E('paridad L',at);if(par(r)^par(f>>4))E('paridad R',at);if(l!=r||l&255)E('L/R',at);if(hd[1]!=1)E('hb1',at);aud.push({s:l>>8,b:hd[2]>>4&1,cl:f>>2&1,cr:f>>6&1})}
 else if(hd[0]>=0x80){const all=[...hd,...subs.flat()];const len=hd[2];if((all.slice(0,3+1+len).reduce((a,b)=>a+b)&255)!=0)E('checksum',at);pk['IF'+hd[0].toString(16)]=all.slice(0,4+Math.min(len,6)).map(x=>x.toString(16)).join(' ')}
 else if(hd[0]==1){for(const s of subs){const cts=(s[1]&15)<<16|s[2]<<8|s[3],n=(s[4]&15)<<16|s[5]<<8|s[6];pk.acr='CTS '+cts+' N '+n}}}
let hist=[];
while(i<L.length-400){const [a,b,c]=S[i];
 if(a in C&&b in C&&c in C){ // control
  if(C[a]!=(+ref(i)[3][1]*2+ +ref(i)[3][0]))E('hs/vs',i);ctl++;hist.push(C[b]|C[c]<<2);if(hist.length>8)hist.shift();i++;continue}
 const pre=hist.join();
 if(b==G&&c==G&&a in T){ // guarda de isla
  if(pre!='5,5,5,5,5,5,5,5')E('preambulo datos',i);if(ctl<12)E('control corto '+ctl,i);ctl=0;isl++;
  for(let k=0;k<2;k++,i++){if(S[i][1]!=G||S[i][2]!=G||T[S[i][0]]!=(12|+ref(i)[3][1]*2|+ref(i)[3][0]))E('guarda',i)}
  let d=[],n=0,first=true;while(!(S[i][1]==G&&S[i][2]==G)){const t=S[i].slice(0,3).map(x=>T[x]);if(t.some(x=>x===undefined)){E('terc4',i);break}
   if((t[0]&3)!=(+ref(i)[3][1]*2+ +ref(i)[3][0]))E('hs/vs isla',i);if((t[0]>>3)!=(first?0:1))E('bit3',i);first=false;
   d.push([t[0]>>2&1,t[1],t[2]]);i++;if(d.length==32){packet(d,i);d=[];n++}}
  if(d.length)E('paquete incompleto',i);maxp=Math.max(maxp,n);
  for(let k=0;k<2;k++,i++){if(S[i][1]!=G||S[i][2]!=G)E('guarda fin',i)}hist=[];continue}
 if(a==V&&b==G&&c==V){ if(pre!='1,1,1,1,1,1,1,1')E('preambulo video',i);if(ctl<12)E('control corto v '+ctl,i);minctl=Math.min(minctl,ctl);ctl=0;i+=2;
  let n=0;while(ref(i)[3][2]=='1'){const r=ref(i),exp=r[4].toUpperCase();const got=[S[i][2],S[i][1],S[i][0]].map(x=>dec(x).toString(16).padStart(2,'0').toUpperCase()).join('');if(got!=exp)vidbad++;for(let k=0;k<3;k++){for(const z of S[i][k])disp[k]+=z=='1'?1:-1;maxd=Math.max(maxd,Math.abs(disp[k]))}vid++;n++;i++;if(i>=L.length-2)break}
  disp=[0,0,0];if(n!=720&&i<L.length-2)E('linea '+n,i);hist=[];continue}
 E('simbolo inesperado',i);i++;ctl=0;hist=[]}
const src=fs.readFileSync('au.txt','utf8').trim().split(/\s+/).map(Number);
let ok=false,off=0;for(let o=0;o<6&&!ok;o++){if(aud.slice(4,aud.length).every((x,k)=>x.s==src[k+4-2+o]||x.s==src[k+4+o-3])){ok=true;off=o}}
let best=-1;for(let o=-6;o<6;o++){let bad=0;for(let k=8;k<aud.length;k++)if(aud[k].s!=src[k+o])bad++;if(best<0||bad<best.bad)best={o,bad}}
const bs=aud.map((x,k)=>x.b?k:-1).filter(k=>k>=0);let cs='';if(bs.length){for(let k=0;k<40&&bs[0]+k<aud.length;k++){const x=aud[bs[0]+k];if(x.cl||x.cr)cs+=k+(x.cl?'L':'')+(x.cr?'R':'')+' '}}
console.log('errores',err,'| pixeles',vid,'malos',vidbad,'| islas',isl,'max paquetes',maxp,'|',pk,'| audio',aud.length,'fuente',src.length,'mejor',best,'| bloques',bs.slice(0,4).join(),'canal:',cs,'| control min',minctl,'disparidad max',maxd);
