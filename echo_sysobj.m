clear; clc; close all;

frameLength = 1024;
inputFile = 'oasis-wonderwall-official-video-0-mhqin.wav';

fileReader = dsp.AudioFileReader(inputFile, ...
    'SamplesPerFrame', frameLength, 'PlayCount', 1);
deviceWriter = audioDeviceWriter('SampleRate', fileReader.SampleRate);

fs = fileReader.SampleRate;
delayTimeSec = 0.4;
feedbackGain = 0.5;
dryWetMix = 0.5; 

delayObj = dsp.Delay('Length', round(delayTimeSec * fs));

prevOutput = 0; 

scope = timescope( ...
    'SampleRate', fs, ...
    'TimeSpanOverrunAction', 'Scroll', ...
    'TimeSpanSource', 'property', ...
    'TimeSpan', 3, ...
    'BufferLength', 3 * fs * 2, ...
    'YLimits', [-1, 1], ...
    'ShowGrid', true, ...
    'ShowLegend', true, ...
    'Title', 'Echo Effect', ...
    'ChannelNames', {'Echo Output', 'Original'});

fig = figure('Name', 'Echo Parameter Tuner', 'Position', [100, 100, 350, 320], ...
    'Color', [0.94, 0.94, 0.94]);

paramList = {
    'delayTimeSec', 0.4, 0.05, 2.0;
    'feedbackGain', 0.5, 0, 0.95;
    'dryWetMix', 0.5, 0, 1
};

yPos = 270;
for i = 1:size(paramList, 1)
    name = paramList{i, 1};
    defaultVal = paramList{i, 2};
    minVal = paramList{i, 3};
    maxVal = paramList{i, 4};

    uicontrol('Style', 'text', 'String', name, ...
        'Position', [10, yPos, 100, 20], 'BackgroundColor', [0.94, 0.94, 0.94]);

    hSlider = uicontrol('Style', 'slider', 'Min', minVal, 'Max', maxVal, ...
        'Value', defaultVal, 'Position', [110, yPos+2, 150, 16]);

    hEdit = uicontrol('Style', 'edit', 'String', sprintf('%.3f', defaultVal), ...
        'Position', [270, yPos, 60, 20]);

    set(hSlider, 'Callback', @(src,~) onSliderChange(src, hEdit, name));
    set(hEdit, 'Callback', @(src,~) onEditChange(src, hSlider, name));

    yPos = yPos - 40;
end

function onSliderChange(hSlider, hEdit, paramName)
    val = get(hSlider, 'Value');
    set(hEdit, 'String', sprintf('%.4f', val));
    applyParameter(paramName, val);
end

function onEditChange(hEdit, hSlider, paramName)
    val = str2double(get(hEdit, 'String'));
    if ~isnan(val)
        set(hSlider, 'Value', val);
        applyParameter(paramName, val);
    end
end

function applyParameter(name, value)
    switch name
        case 'delayTimeSec'
            newLength = max(round(value * fs), 1);
            delayObj.Length = newLength;
        case 'feedbackGain'
            feedbackGain = value;
        case 'dryWetMix'
            dryWetMix = value;
    end
end 


while ~isDone(fileReader)
    audioIn = fileReader();

    audioOut = zeros(size(audioIn));

    for i = 1:frameLength
        delayedSignal = delayObj(audioIn(i));
        
        inputToDelay = audioIn(i) + (feedbackGain * delayedSignal);
        
        delayObj(inputToDelay);
        
        audioOut(i) = (1 - dryWetMix) * audioIn(i) + dryWetMix * delayedSignal;
    end

    deviceWriter(audioOut);
    scope([audioOut(:,1), audioIn(:,1)]);

    drawnow limitrate;
end

release(fileReader);
release(deviceWriter);
release(scope);
release(delayObj);
