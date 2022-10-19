
function [A mse] = psnr_mse(Im1,Im2)

    
    [M,N]=size(Im1);

    Im1=im2double(Im1);    % convert to doubles
    Im2=im2double(Im2);       
    mse=sum(sum((Im1-Im2).*(Im1-Im2)))/(M*N);
    A=10*log10(255.^2/(mse));
    A=max(A);
    mse=min(mse);
    