function J = steerGaussFilterOrder2(I, theta, sigma)
%% Steerable filter with the second derivatives of Gaussian
    theta = -theta * (pi / 180);

%% determine necessary filter support (for Gaussian)
    Wx = floor((8 / 2) * sigma); 
    if Wx < 1
      Wx = 1;
    end
    x = [-Wx : Wx];

    [xx, yy] = meshgrid(x, x);

    g0 = exp(-(xx.^2 + yy.^2) / (2 * sigma^2)) / (sigma * sqrt(2 * pi));
    G2a = -g0 / sigma^2 + g0 .* xx.^2 / sigma^4;
    G2b =  g0 .* xx .* yy / sigma^4;
    G2c = -g0 / sigma^2 + g0 .* yy.^2 / sigma^4;

%% compute image gradients (using separability)
    I2a = imfilter(I, G2a, 'same', 'replicate');
    I2b = imfilter(I, G2b, 'same', 'replicate');
    I2c = imfilter(I, G2c, 'same', 'replicate');

%% evaluate oriented filter response
    J = (cos(theta))^2 * I2a + sin(theta)^2 * I2c - 2 * cos(theta) * sin(theta) * I2b;
end
%%