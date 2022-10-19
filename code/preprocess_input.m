function output = preprocess_input(input) 
    output = imresize(input(1 : 690, 181 : 1100, :), [480, 640]);
end
