function output = gaussFilter(I, sigma)
    output = I;
    sigma = round(min(size(I, 1), size(I, 2)) / sigma);
    ksize = double(3 * sigma);
    window = fspecial('gaussian', [1, ksize], sigma);
    for i = 1 : size(I, 3)
        ret = imfilter(I(:, :, i), window, 'replicate');
        ret = imfilter(ret, window', 'replicate');
        output(:, :, i) = ret;
    end
end
