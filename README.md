## Reproduce Guide
Follow the following steps to reproduce.
For data analysis script go to `/internals/data_analysis`

## Compile Binary to Warm Up Machine
At root dir, do `make`.

## Build Docker
In `/internals`, do `bash build.sh`.

## Start Mem Tracer
In internals, do `python3 memory_tracer.py`.

## Experiment Runner Config
Files are under `/examples/green-lab-exp`.
Note that while running experiment, mem tracer has to be running.
Use `python3 experiment-runner/ examples/green-lab-exp/RunnerConfig.py` to run the experiments.