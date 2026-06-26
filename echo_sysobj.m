clear; clc; close all;

frameLength = 1024;
inputFile = 'y2mate.mp3';

fileReader = dsp.AudioFileReader(inputFile, ...
    'SamplesPerFrame', frameLength, 'PlayCount', 1);
deviceWriter = audioDeviceWriter('SampleRate', fileReader.SampleRate);

fs = fileReader.SampleRate;
delayTimeSec = 0.4;
feedbackGain = 0.5; 

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
    'Title', 'Echo Effect (Delay + Feedback)', ...
    'ChannelNames', {'Echo Output', 'Original'});

while ~isDone(fileReader)
    audioIn = fileReader();

    audioOut = zeros(size(audioIn));

    for i = 1:frameLength
        inputToDelay = audioIn(i) + (feedbackGain * prevOutput);

        delayedSignal = delayObj(inputToDelay);

        audioOut(i) = delayedSignal;

        prevOutput = delayedSignal; 
    end

    deviceWriter(audioOut);
    scope([audioOut(:,1), audioIn(:,1)]);

    drawnow limitrate;
end

release(fileReader);
release(deviceWriter);
release(scope);
release(delayObj);