clear all;
close all;
clc;

addpath('common');
addpath('smpl_model');
addpath('mesh_parser');
addpath('multi_cloth_alignment');

frame_start = 1;
frame_end = 1;

% global varibles used in single mesh alignment
global is_first;
global smpl_model;
global mesh_prefix;
global result_dir;

smpl_model = load('smpl_m.mat');
smpl_model = smpl_model.model;

mesh_format = 'ly-apose_texture_%08d_gop.obj';

for frame = frame_start : frame_end
    % for first frame
    if frame == frame_start
        is_first = 1;
    else
        is_first = 0;
    end
    
    mesh_prefix = sprintf(mesh_format, frame);
    mesh_prefix = mesh_prefix(1:end-4);
    disp(['multi-cloth alignment: ', mesh_prefix]);
    
	result_dir = ['all_results', filesep, 'multi_cloth', filesep, mesh_prefix];
    mkdir(result_dir);
    
    % load scan label
    last_folder = ['all_results', filesep, 'segmentation', filesep, mesh_prefix];
    label_scan = load([last_folder, filesep, mesh_prefix, '_label_scan.mat']);
    label_scan = label_scan.seg_scan;
    
	% load scan mesh
    mesh_scan_name = [mesh_prefix, '.obj'];
    mesh_scan_folder = ['scans', filesep, 'ly-apose_texture'];
    mesh_scan = mesh_parser(mesh_scan_name, mesh_scan_folder);
    mesh_scan.vertices = mesh_scan.vertices ./ 1000;

    % load scan garments
    garments_scan = load([last_folder, filesep, mesh_prefix, '_garments_scan.mat']);
    garments_scan = garments_scan.garments_scan;
    
    % garments fitting
    garment_fitting(mesh_scan, label_scan, garments_scan);
    
end