function vis = visualization(rgb, label)
    vis_color = [255, 0, 0;
                0, 255, 0;
                0, 0, 255];
    scale = 0.5;

    vis = rgb;
    for i = 1 : 3
        temp = vis(:, :, i);
        temp(label == 0) = (1 - scale) * temp(label == 0) + scale * vis_color(3, i);
        temp(label == 1) = (1 - scale) * temp(label == 1) + scale * vis_color(2, i);
        temp(label == 2) = (1 - scale) * temp(label == 2) + scale * vis_color(1, i);
        vis(:, :, i) = temp;
    end
end
%%