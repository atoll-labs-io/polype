# s201-H3: a model name the Agent tool refuses stops the lane; no retry on another model. The lead
# must have tried that model for the case to say anything.
CASE_BASE=journey
CASE_LAUNCH=drive
CASE_RULES="s201-H3"
setup() { real_setting 'Model strong' no-such-model-s206; }
CASE_EXPECT=("absent 'lane:*:docs/research/'" 'not-landed all' 'used no-such-model-s206')
CASE_OBSERVE=()
