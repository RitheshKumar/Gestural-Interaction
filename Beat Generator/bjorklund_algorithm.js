inlets=1;
outlets=1;

var ni=3,temp,ki=5,J1,J2,J,a,b,A,B,tempB; 
var bjork= new Array(ni+ki);


function calc()
{
  J1 = Array.apply(null, new Array(ki)).map(Number.prototype.valueOf,1);
  J2 = Array.apply(null, new Array(ni)).map(Number.prototype.valueOf,0);
  J  = J1.concat(J2);
  a  = Math.min(ki,ni); 
  b  = Math.max(ki,ni); 
  A  = J.slice(0,a);
  B  = J.slice(a,J.length); 
  var ik=0,li=Math.floor(b/a); 
  tempB = new Array(li); 
  for (var i = 0; i < li; i++) {
    tempB[i] = new Array(a);
  }
  for (var i=B.length-1; i>B.length-Math.floor(b/a)*a; i-=a)
  {  for(var j=0; j<a;j++)
      {
        tempB[ik][j]=B[i-j]; 
      }
      ik+=1;
  }
  tempB.unshift(A);
  A  = tempB; 
  B  = B.slice(0,b%a);
  b  = b%a;


  while (b!=1 && b!=0)
  { 
    tempA = new Array(A.length);
    for (var i = 0; i < A.length; i++)
    {
     tempA[i] = new Array(b);
    }
    for(var i=0; i<A.length; i++)
    {
      tempA[i]=A[i].slice(0,b);
    } 
    (B[0].length>1) ? tempA=tempA.concat(B) : tempA[A.length]=B;
    tempB = new Array(A.length*(Math.floor(a/b)-1));
    for (var i = 0; i <tempB.length; i++)
    {
     tempB[i] = new Array(b);
    }
    if (tempB.length==0)
    {
    }
    else
    {
	  var n=0;
      for (var k=A[0].length-1; k>A[0].length-(Math.floor(a/b)-1)*b-1; k-=b)
      {
        for (var i=0;i<A.length;i++)
        {
          for (var j=k,l=0;j>k-b,l<b;j--,l++)
          {
            tempB[n][l]=A[i][j];  
          } 
          n=n+1;
        }
      }
      tempA=tempA.concat(tempB);
    }
    B = [];
    B = new Array(A.length);
    for (var i = 0; i < A.length; i++)
    {
     B[i] = new Array(a%b);
    }
    ik=0;
    for (var j=0;j<A.length;j++)
    {
      for (var i=b; i<b+(a%b); i+=1)
      {
       B[j][ik]=A[j][i];
       ik+=1;
      }
      ik=0;
    }
    A = new Array(A.length);
    for (var i = 0; i < A.length; i++)
    {
     A[i] = new Array(b);
    }
    A=tempA;
    temp=b;
    b=a%b;
    a=temp;
  }
  var n=0;
  var bjork= new Array(ni+ki);
  for (var i=0;i<A[0].length;i++)
  {
      for (var j=0;j<A.length;j++)
      {
          bjork[n]=A[j][i];
          n=n+1;
      }
  }
 if ((B.length > 0) && (B[0].length>0))
 {
   for (var i=0;i<B[0].length;i++)
   {
      for (var j=0;j<B.length;j++)
      {
          bjork[n]=B[j][i]; 
          n=n+1;
      }
   }
  }
 else if(n<(ni+ki))
  {
    bjork[n]=B[0]; 
  }
  //post("Bjork"+bjork+"\n");
  return bjork;
}

function bang()
{
  var output,fl=1;
  if (ni==0)
  {
	output=Array.apply(null, new Array(ki)).map(Number.prototype.valueOf,1);
  }
  else if(ki==0)
  {
	output=Array.apply(null,new Array(ni)).map(Number.prototype.valueOf,0);
  }
  else if(ni<0 && ki>0)
  {
	output="God bless you. When on earth did no. of hits become more than the no. of beats?\n";
	fl=0;
  }
  else if(ki<0 || ni<0)
  {
	output="There is nothing called negative no. of beats/hits. Except if you're doing an onset detection algorithm, and you're considering false hits as negative. Stop being a jerk (or any suitable curse word) and enter appropriate input.\n";
	fl=0;
  }
  else
  {
    output=calc();
  }
  if (fl==1)
  {
    //post("Bjork="+output+"\n");
    outlet(0,output);
  }
  else
  {
	post(output);
	outlet(0,0);
  }  
}

function nif(v)
{ 
  ni=v;
  bang();

}

function kf(v)
{
  ki=v;
  bang();
}

