//A program to visualize the Euclidean Space, visualized through Bjorklunds' Algorithm
//Nth beat is visually highlighted, given that there is a metronome input

sketch.default2d();
sketch.fsaa = 1;

outlets=3;
var size = 0.9,ns=2;
var bjork= new Array(ns);
var met=new Array(ns);
var X,Y,last_y = 0;
metinit(ns);
draw();

function draw()
{
 
  with (sketch)
  {glclear();
   glclearcolor(0.2,0.5,0.5);
  }
  for (var i=0,j=ns-1;i<ns,j>=0;i++,j--)
  {    
       X=-size*Math.cos((i*(2*Math.PI)+2*Math.PI)/ns);
       Y=-size*Math.sin((i*(2*Math.PI)+2*Math.PI)/ns);
       with (sketch)
       {
	    glcolor(0.2,0.2,0.2);
            lineto(X,Y);
            glcolor(0.2+0.3*bjork[j]+met[j]*0.4,0.2+0.7*bjork[j]+met[j]*0.4,0.2+0.2*bjork[j]+met[j]*0.7);
	    circle(0.10);
       }
  } 
}

function msg_int(v)
{
	ns =v;
	notifyclients();
	bang();
}

function bang()
{
	draw();
	refresh();
	outlet(0,bjork);
}
function ondrag(x,y,but,cmd,shift,capslock,option,ctrl)
{
	var f,dy;
	dy = y - last_y;
	f= ns-dy;
	msg_int(f);
	last_y = y;
	
}

function text(v)
{
	ns = arguments.length;
	for (var i=0; i<ns; ++i)
	{
		bjork[i]=arguments[i];
	}
	bang();
}

function metro(v)
{
    metinit(ns);
    met[v]=1;
    outlet(1,met);
    outlet(2,ns);
    bang();
}
function metinit(ns)
{
   for (var i=0;i<ns;i++)
    { 
    met[i]=0;
    }
}
