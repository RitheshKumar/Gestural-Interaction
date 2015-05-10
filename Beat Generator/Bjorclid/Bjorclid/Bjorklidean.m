//
//  Bjorklidean.m
//  Bjorclid
//
//  Created by Rithesh Kumar on 5/8/15.
//  Copyright (c) 2015 Rithesh Kumar. All rights reserved.
//

#import "Bjorklidean.h"

@implementation Bjorklidean

-(void) arrayInit: (int *)array  withbeats: (int)beats  withhits: (int)hits
{
    for (int i=0; i<(hits);i++)
    {
      array[i]=1;
    }
    for (int i=hits; i<beats; i++)
    {
      array[i]=0;
    }
}



-(void) bjorcimp_noofbeats: (int) beats noofhits: (int) hits
{
    _beats=beats;
    _hits =hits;
    int J[beats];
    [self arrayInit:J withbeats:beats withhits:hits];
    int a=MIN(hits, (beats-hits)),b=MAX(hits, (beats-hits));
    NSMutableArray * A_temp = [[NSMutableArray alloc]init], *B_temp = [[NSMutableArray alloc]init];
    NSMutableArray *temp =[[NSMutableArray alloc]init];
    for(int i=0; i<a;i++)
    {
        [A_temp insertObject:[NSNumber numberWithInt:J[i]] atIndex:i];
    }
    for (int i=a,j=0;i<beats;i++,j++)
    {
        [B_temp insertObject:[NSNumber numberWithInt:J[i]] atIndex:j];
    }
    NSMutableArray * tempB = [[NSMutableArray alloc] init];
    for (int i=(beats-a-1); i>(beats-a)-(int)(b/a)*a; i-=a)
    {
        for (int j=0; j<a; j++)
        {
            [temp addObject:[B_temp objectAtIndex:(i-j)] ];
        }
        [tempB addObject:[temp mutableCopy]];
        [temp removeAllObjects];
    }
    NSMutableArray *A = [[NSMutableArray alloc]initWithObjects:[A_temp mutableCopy], nil];
    [A addObjectsFromArray:[tempB mutableCopy]];
    NSMutableArray *B = [[NSMutableArray alloc]init];
    for (int i=0;i<(b%a);i++)
    {
        [B insertObject:[B_temp objectAtIndex:i]  atIndex:i];
    }
    b = b%a;
    
    while (b!=1 && b!=0)
    {
        [A_temp removeAllObjects];
        [tempB removeAllObjects];
        
        for (int i=0; i<[A count]; i++)
        {
            for( int k=0; k<b; k++)
            {
                [temp addObject:A[i][k]];
            }
            [A_temp addObject:[temp mutableCopy]];
            [temp removeAllObjects];
        }
        [A_temp addObject:[B mutableCopy]];
        if((A.count)*(a/b-1)==0)
        {}
        else
        {
            [B_temp removeAllObjects];
            for (int k=(int)[A[0] count]-1; k>[A[0] count]-((a/b)-1)*b-1; k-=b)
            {
                for (int i=0;i<A.count;i++)
                {
                    for (int j=k,l=0;l<b;j--,l++)
                    {
                        [temp addObject:A[i][j]];
                    }
                    [tempB addObject:[temp mutableCopy]];
                    [temp removeAllObjects];
                }
            }
            [A_temp addObjectsFromArray:[tempB mutableCopy]];
        }
        [B removeAllObjects];
        for (int j=0;j<[A count];j++)
        {
            for (int i=b; i<b+(a%b); i+=1)
            {
                [temp addObject:A[j][i]];
            }
            [B addObject:[temp mutableCopy]];
            [temp removeAllObjects];
        }
        
        [A removeAllObjects];
        [A addObjectsFromArray:A_temp];
        int tmp=b;
        b=a%b;
        a=tmp;
    }
    
    NSMutableArray * bjork= [[NSMutableArray alloc]init];
    for (int i=0;i<[A[0] count];i++)
    {
        for (int j=0;j<A.count;j++)
        {
            [bjork addObject:A[j][i]];
        }
    }
    if (B.count > 1)
    {
        for (int i=0;i<[B[0] count];i++)
        {
            for (int j=0;j<B.count;j++)
            {
                [bjork addObject:B[j][i]];
            }
        }
    }
    else if(bjork.count<(beats))
    {
        [bjork addObjectsFromArray:B];
    }
    NSLog(@"%@",bjork);
    //NSLog(@"Bjork's count is %lu",[bjork count]);
}


@end
