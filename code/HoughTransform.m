function [outputline, status] = HoughTransform(I)
%% exatract image boundary based on Canny
BW = edge(I, 'canny');
    for i = 1 : size(BW, 1)
        flag = 0;
        for j = size(BW, 2) : -1 : 1
            if flag == 0 && BW(i, j) == 0
                continue
            else
                if flag == 0 && BW(i, j) == 1
                    flag = 1;
                    BW(i, j) = 0;
                else
                    if flag == 1 && BW(i, j) == 1
                        BW(i, j) = 0;
                    else
                        break
                    end
                end
            end
        end
    end

%% perform Hough Transform
[H, T, R] = hough(BW);
P = houghpeaks(H, 1);
lines = houghlines(BW, T, R, P);

%% select the longest line
    if length(lines) == 1
        outputline = lines;
    else
        lenarray = zeros(length(lines), 1);
        for k = 1 : length(lines)
            point1 = lines(k).point1;
            point2 = lines(k).point2;
            lenarray(k) = sum((point1 - point2).^2);
        end
        [~, pos] = max(lenarray);
        outputline = lines(pos);
    end

    if(isempty(outputline))
        status = 0;
        outputline = 0;
        return
    end

%% extend the detected line
    [height, width] = size(I);

    point1 = outputline.point1; point2 = outputline.point2;
    temp1 = point1; temp2 = point2;
    leftflag = 1; rightflag = 1;
    interval = 5; index = 3;

    while (leftflag && point1(1) > interval && point1(2) > 1) || (rightflag && point2(1) < width - interval + 1 && point2(2) < height)
        if leftflag && point1(1) > interval && point1(2) > 1
            temp1(1) = point1(1) - interval;
            temp1(2) = round(point1(2) - interval * (point2(2) - point1(2)) / (point2(1) - point1(1)));
            lbound = max(1, temp1(1) - index);
            if temp1(2) > 1 && sum(BW(temp1(2), lbound : temp1(1) + index)) > 0
                temp1(1) = temp1(1) - length((lbound : temp1(1) + index)) + index + find(BW(temp1(2), lbound : temp1(1) + index) > 0, 1);
                point1 = temp1;
            else
                leftflag = 0;
            end
        end

        if rightflag && point2(1) < width - interval + 1 && point2(2) < height
            temp2(1) = point2(1) + interval;
            temp2(2) = round(point2(2) + interval * (point2(2) - point1(2)) / (point2(1) - point1(1)));
            rbound = min(temp2(1) + index, width);
            if temp2(2) < height && sum(BW(temp2(2), temp2(1) - index : rbound)) > 0
                temp2(1) = temp2(1) - index - 1 + find(BW(temp2(2), temp2(1) - index : rbound) > 0, 1);
                point2 = temp2;
            else
                rightflag = 0;
            end
        end
    end
    outputline.point1 = point1;
    outputline.point2 = point2;
    status = 1;
end
%%