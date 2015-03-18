clear all;
close all;
clc;
% Implementation of Bjorklund's Algorithm using Euclidean Sets, as
% described in chapter 5 of "Musical Rhythm in the Euclidean Plane" by
% Perouz Taslakian. 
% http://student.ulb.ac.be/~ptaslaki/publications/phdThesis-Perouz.pdf
% Condition:
% n>k
% n is the total no. of beats, k is the no. of hits/onsets

n=2; k=2;
% n=5;k=3;
% n=13;k=5;

J=[ones(1,k),zeros(1,n-k)];             %initialize
a=min(k,(n-k));
b=max(k,(n-k));
A=J(1,1:a);
B=J(1,1+a:end);
tempB=B(:,end:-1:end-floor(b/a)*a+1);   %holds int(b/a) strings of size a
                                        %starting from the rightmost end
tempB=reshape(tempB,[floor(b/a),a]);    %arranges, such that a strings are 
                                        %one below another
tempA=A(:,1:a);
A=[tempA;tempB];
B=B(1,1:mod(b,a));
b=mod(b,a);

while (b~=1 && b~=0)                    % Subtraction Step
    tempA=[A(:,1:b);B];
    tempB=A(:,end:-1:end-(floor(a/b)-1)*b+1); % holds int(a/b)-1 strings of 
                                        % size b, starting from the
                                        % rightmost end of A
    [j,k]=size(tempB);
    tempB=reshape(tempB,[j*k/b,b]);     %re-arranges int(a/b)-1 strings 
                                        %of size b one below another
    tempA=[tempA;tempB];
    B=A(:,b+1:b+mod(a,b));              %the left out strings in A become B
    A=tempA;
    temp=b;                             
    b=mod(a,b);                         %new values of A and B
    a=temp;
end;
bjork=zeros(1,n);
[j,k]=size(A);
bjork(1:j*k)=reshape(A,[1 j*k]);
bjork(j*k+1:end)=B'



% Rubbish Dump:
%
% tempA=A(:,1:floor(b/a)*a);
%     if (floor(a/b)*b~=length(A(1,:))-floor(a/b)*b+1)
%         tempA=[tempA;A(:,end-(floor(a/b)-1)*b+1:end)];
%     end;