function [unary] = get_unary(mesh_scan, mesh_smpl, prior, k)

global is_first;
global mesh_prefix;
global result_dir;

n_scan = size(mesh_scan.vertices, 1);
n_smpl = size(mesh_smpl.vertices, 1);

% get scan adjacancy map
n_edges = size(mesh_scan.edges, 1);
adj_map_scan = zeros(n_scan, n_scan);
for i = 1 : n_edges
    edge = mesh_scan.edges(i, :);
    adj_map_scan(edge(1), edge(2)) = 1;
    adj_map_scan(edge(2), edge(1)) = 1;
end

% unary: data likelihood
unary_data = zeros(n_smpl, k);

if is_first
    % color feature
    color_start = [[164, 140, 122]; [217, 220, 219]; [69, 71, 70]];
    color_start = rgb2hsv(double(color_start) / 255);
    
    color_hsv = rgb2hsv(double(mesh_scan.colors) / 255);
    
    % sdf feature
    sdf_values = importdata('sdf_value.txt');
    sdf_values = sdf_values(:, 2);
    
    sdf_start = [0.2066; 0.8474; 0.4405];
    
    % total feature;
    total_feature = [color_hsv, sdf_values];
    total_start = [color_start, sdf_start];
    
    % k-means on scan
    labels_k_means = kmeans(total_feature, k, 'Start', total_start);
    
    m_k = mesh_scan;
    m_k.colors = render_kmeans(labels_k_means);
    mesh_exporter([result_dir, filesep, mesh_prefix, '_kmeans.obj'], m_k, true);
    
    % node i -> scan point v -> v's neighbors
    ind_scan = matching_pair(mesh_scan, mesh_smpl, 2);
    for i = 1 : size(ind_scan, 1)
        neighbors = adj_map_scan(ind_scan(i), :);
        [~, neighbors_ind] = find(neighbors == 1);
        neighbor_label = labels_k_means(neighbors_ind);
        
        unary_data(i, 1) = sum(-log((neighbor_label == 1) + 1e-6));
        unary_data(i, 2) = sum(-log((neighbor_label == 2) + 1e-6));
        unary_data(i, 3) = sum(-log((neighbor_label == 3) + 1e-6));
    end
    
    m_k = mesh_smpl;
    m_k.colors = render_unary(unary_data);
    mesh_exporter([result_dir, filesep, mesh_prefix, '_unary_data.obj'], m_k, true);
else

end

% unary: prior
unary_prior = zeros(n_smpl, k);   
labels_skin(prior.skin == 0) = 100;
labels_skin(prior.skin == 1) = -200;
labels_skin(prior.skin == 0.5) = 0;

labels_shirt(prior.shirt == 0) = 100;
labels_shirt(prior.shirt == 1) = -200;
labels_shirt(prior.shirt == 0.5) = 0;

labels_pants(prior.pants == 0) = 100;
labels_pants(prior.pants == 1) = -200;
labels_pants(prior.pants == 0.5) = 0;

unary_prior(:, 1) = labels_skin;
unary_prior(:, 2) = labels_shirt;
unary_prior(:, 3) = labels_pants;

% total unary
unary = unary_data + unary_prior;

m_k = mesh_smpl;
m_k.colors = render_unary(unary);
mesh_exporter([result_dir, filesep, mesh_prefix, '_unary_all.obj'], m_k, true);

end

