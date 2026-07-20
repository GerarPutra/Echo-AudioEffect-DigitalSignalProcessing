function realtime_mic_echo()
clear; clc; close all;

fs = 44100;              
frameSize = 256;         

micReader = audioDeviceReader('SampleRate', fs, ...
    'SamplesPerFrame', frameSize, ...
    'NumChannels', 1); 

speakerWriter = audioDeviceWriter('SampleRate', fs);

fprintf('Latency due to device buffer: %f seconds.\n', micReader.SamplesPerFrame / micReader.SampleRate);

delayTimeSec = 0.4;
feedbackGain = 0.5;
dryWetMix = 0.5; 

delayLength = round(delayTimeSec * fs);
delayObj = dsp.Delay('Length', delayLength);

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
    'ChannelNames', {'Echo Output', 'Mic Input'});

fprintf('Running... Speak into mic. Press Ctrl+C to stop.\n');

while true
    audioIn = micReader();

    audioOut = zeros(frameSize, 1);

    for i = 1:frameSize
        delayedSignal = delayObj(audioIn(i));
        inputToDelay = audioIn(i) + (feedbackGain * delayedSignal);
        delayObj(inputToDelay);
        audioOut(i) = (1 - dryWetMix) * audioIn(i) + dryWetMix * delayedSignal;
    end

    speakerWriter(audioOut); 

    scope([audioOut, audioIn]);

    drawnow limitrate;
end

release(micReader);
release(speakerWriter);
release(scope);
release(delayObj);
end