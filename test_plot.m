clear all;
close all;
clc;

%% Tropo
% Starting date for the files
startDate = datetime(2020, 11, 1); % Modify this to your starting date
numDays = 7; % Number of days to process
baseName = '_10KIR0.trp'; % Common part of the filename
dataDir = 'ztd/GRE'; % Replace with the path to your files
outputFile = 'combined_data.csv'; % Output CSV file name
dataperday=288;
datasixdays=dataperday*6;
% Initialize an empty array to store the data
combinedData = [];

% Loop through each day
for day = 0:(numDays - 1)
    % Generate the current file name
    currentDate = startDate + days(day);
    fileName = strcat(datestr(currentDate, 'yyyy-mm-dd'), baseName);
    filePath = fullfile(dataDir, fileName);
    
    % Check if the file exists
    if isfile(filePath)
        try
            % Attempt to read the file as a text file
            fileData = readmatrix(filePath, 'FileType', 'text'); 
        catch
            % Fallback: Read file with dlmread if readmatrix fails
            disp(['Using fallback for file: ', filePath]);
            fileData = dlmread(filePath, ' '); % Assumes space-separated values
        end
        
        % Append the data to the combined array
        combinedData = [combinedData; fileData]; %#ok<AGROW>
    else
        disp(['File not found: ', filePath]);
    end
end

% % Write the combined data to a CSV file
% writematrix(combinedData, outputFile);
% 
% disp(['Combined data written to ', outputFile]);
combinedData(:, end+1) = combinedData(:, 4) + combinedData(:, 2);
%figure(1)

day7points = dataperday; % Points for prediction (1 day's worth)

% Independent variable (time steps)
x = (1:datasixdays)'; % Time steps for 6 days

% Dependent variable (column 6 of combinedData)
y = combinedData(1:datasixdays, 6);

% Perform linear regression
p = polyfit(x, y, 3); % Fit a straight line (1st-degree polynomial)

% Predict data for day 7
x_day7 = (datasixdays + 1):(datasixdays + day7points); % Time steps for day 7
y_day7 = polyval(p, x_day7); % Predicted values for day 7

% Plot the results
figure(2);
hold on;
errorbar(combinedData(:,6),combinedData(:,3),LineWidth=3)
plot(x, y, 'b.', 'DisplayName', 'Data (6 days)'); % Original data
plot(x_day7, y_day7, 'r-', 'DisplayName', 'Prediction (Day 7)'); % Prediction


legend('show');
xlabel('Time steps');
ylabel('CombinedData Column 6');
title('Linear Fit on CombinedData(:,6) and Prediction for Day 7');
grid on;

%% position
startDate = datetime(2023, 11, 1); % Modify this to your starting date
endDate = datetime(2024, 2, 26); % Modify this to your ending date
baseName = '_10KIR0.stacov'; % Common part of the filename
dataDir = 'gps_data/GRE'; % Replace with the path to your files
outputFile = 'x_y_z_variances.csv'; % Output CSV file name
yearStr = datestr(startDate, 'yyyy');
% Calculate the number of days between startDate and endDate
numDays = days(endDate - startDate) + 1; % +1 to include the end date

pathfilenotfound=0;
% Initialize an empty array to store the data
combinedData = [];
x=[];
y=[];
z=[];

% Loop through each day
for day = 0:(numDays - 1)
    % Generate the current file name
    currentDate = startDate + days(day);
    fileName = strcat(datestr(currentDate, 'yyyy-mm-dd'), baseName);
    filePath = fullfile(dataDir, fileName);
    x = [];
    y = [];
    z = [];
    
    % Check if the file exists
    if isfile(filePath)
        try
            % Open the file
            fid = fopen(filePath, 'r');
            
            % Read the file line by line
            while ~feof(fid)
                line = fgetl(fid);
                
                % Check if the line contains "STA X", "STA Y", or "STA Z"
                if contains(line, 'STA X') %|| contains(line, 'STA Y') || contains(line, 'STA Z')
                    % Parse the line to extract the variable and variance
                    tokens = textscan(line, '%d %s %s %s %f %*s %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
                    if ~isempty(tokens{5}) && ~isempty(tokens{6})
                        % Append the data to the combined array
                        x = [x; tokens{5:6}]; %#ok<AGROW>
                    end
                end
                if contains(line, 'STA Y') %|| contains(line, 'STA Y') || contains(line, 'STA Z')
                    % Parse the line to extract the variable and variance
                    tokensy = textscan(line, '%d %s %s %s %f %*s %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
                    if ~isempty(tokensy{5}) && ~isempty(tokensy{6})
                        % Append the data to the combined array
                        y = [y; tokensy{5:6}]; %#ok<AGROW>
                    end
                end
                if contains(line, 'STA Z') %|| contains(line, 'STA Y') || contains(line, 'STA Z')
                    % Parse the line to extract the variable and variance
                    tokensz = textscan(line, '%d %s %s %s %f %*s %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
                    if ~isempty(tokensz{5}) && ~isempty(tokensz{6})
                        % Append the data to the combined array
                        z = [z; tokensz{5:6}]; %#ok<AGROW>
                    end
                end
            end

            % Close the file
            fclose(fid);
        catch ME
            disp(['Error reading file: ', filePath, '. Error: ', ME.message]);
        end
    else
        disp(['File not found: ', filePath]);
        pathfilenotfound=1;
    end
    if pathfilenotfound == 0
    currentRow = table({datestr(currentDate, 'yyyy-mm-dd')}, x, y, z, ...
                       'VariableNames', {'Date', 'X', 'Y', 'Z'});

    combinedData = [combinedData; currentRow]; %#ok<AGROW>
    end
    pathfilenotfound = 0;
end

% Save the combined data to a CSV file
% Extract baseName without the .stacov extension
fileBaseName = erase(baseName, '.stacov'); % Alternatively, use strrep(baseName, '.stacov', '');

% Create the final filename
%outputFileName = strcat(fileBaseName, '_x_y_z.csv');
outputFileName = strcat(fileBaseName, '_', yearStr, '_x_y_z.csv');
% Write the table to the file
%writetable(combinedData, outputFileName);
if ~isempty(combinedData)
    writetable(combinedData, outputFileName);
    disp(['Data saved to ', outputFile]);
    matFileName = strrep(outputFileName, '.csv', '.mat'); % Replace .csv with .mat
    save(matFileName, 'combinedData');
else
    disp('No data to save.');
end

