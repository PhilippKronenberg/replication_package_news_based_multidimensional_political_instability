function y = lag(x,nlags)

if nlags==0
    y=x;
else
y = x(:);
y = [ ones(nlags,1)*NaN
        y(1:end-nlags) ];
end