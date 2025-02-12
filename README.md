# Summary
Sybil is a *prototype* technology demonstrator intended to explore improving chatbot capabilities by drawing inspiration from multiple personality disorder. Essentially, It is hoped that aggregating output from multiple, potentially conflicting, "personalities" might result in a more interesting chatbot. Sybil's namesake is the psuedonym of the famous mental patient who struggled with this very severe disorder.

More generally, this code demonstrates a hopefully novel method of stitching ollama shells together and aggregating their output. It could be adapted for many other purposes! You are only limited by your imagination and the nature of the LLMs you choose to stitch together.

# Warning
I want to be as clear as I can possibly be - this is a *prototype* and unfit for any real world use. It also uses an architecture that is literally inspired by multiple personality disorder. You should *not* rely on Sybil's output for any serious guidance on your personal beliefs or problems. Sybil may lie, Sybil may make excuses, Sybil may contradict moral guidelines and stated objectives - this can actually become quite over-the-top and grandiose!

With that said, it kind of makes for a better conversation when Sybil does these things - it just feels more "real" since we humans *routinely* make mistakes and contradict ourselves. In that sense, Sybil is definitely succeeding at being a more engaging chatbot I suppose!

In general, however, you should always think critically about any advice someone gives you - this extends to LLMs. Frankly, it is disturbing how often LLMs are treated as oracles of objective truth when they are basically really sophisticated and fast dice rollers. In general, any LLM output should be considered with at most the weight of some random guy posting on the internet. Would you make an important decision based on the advice of an "internet rando"? Do you actually get surprised when they are wrong or trying to deceive or hurt you? Think about it...

I can't believe I actually have to emphasize the above, but sadly I do. You know, if those who actually want a true AGI system were to get their wish all of these caveats would be amplified a thousand fold. After all, it is reasonable to expect that a more intelligent system would be better at hurting or misleading you - we've made plenty of science fiction movies to that effect!

# Architecture
Sybil is basically a just collection of ollama shells running in logically isolated podman containers with input and output between these sessions mediated by an Erlang application. These containers are referred to as "herdates" following the llama analogy.

diagram todo

I've done a lot of experimentation with the above architecture and I must say there are plenty of fascinating way this cat could be skinned - in no way do I think I've found the best solution. In fact, I would love to see someone smarter than me come up with a better one!

# Running Sybil
Sybil is pretty easy to get up and running:

* On a Linux system with podman installed, run `./start.sh` - this will build and start the pod.
* Connect to a shell within the `sybil_dev-erlang` container.
* `cd sybil_core`
* Run `rebar3 shell` to build and start the application.
* When prompted, you can run `sybil:chat().` in the Erlang shell to start a chat prompt loop.
* You might want to tail the `sybil.log` file in order to monitor the innards of the system.

Note that the first startup will take a long time, simply due to having to download the ollama models - subsequent startups should be significantly faster.

If you want to see what a given ollama shell is up to directly, that is also easy:

* Connect to the appropriate herdmate's shell.
* run `su dubuntu` to become the user running the shell.
* run `tmux attach` to connect to the shell.

Note that you can also directly connect to a herdmate via SSH - in fact, this is what the Erlang code is doing internally! There is a convenient `dev-inspector` container provided with common networking tools if you need to diagnose any pod networking issues as well. Once you have access to the ollama session, you can kill any infinite inference loops using Ctrl-C too.

# Performance
Sybil is *not fast at all*, although how slow will depend on your hardware. Obviously, having to feed and backfeed queries through several models is going to take longer than usually expected. With that said, this system has been configured to utilize GPU-acceleration via podman containers which is orders of magnitude faster than CPU inference. Although easiest to configure on Linux, it should be noted that WSL does support exposing GPU resources to podman!

# Areas for Improvement
* As a prototype, Sybil does not follow all Erlang/OTP design principles - for example, herdmates only have a start() function and no supervisor. Adding these would increase the resiliance of the system. There are also no type `spec` hints.
* As a prototype, Sybil does not have any timeouts for herdmate output - it is possible for a herdmate's ollama session to enter an infinite inference loop and hang the system. Adding timeouts and a graceful method of restarting misbehaving ollama instances would also increase the resiliance of the system.
* tmux and SSH are used to interact with the herdmates' ollama sessions - this is basically to just simplify state management and let ollama's shell handle the actual API calls. This may or may not be a good solution depending on your needs.

# Potential Questions
* *Do I need an NVIDIA GPU?* - As configured, yes. However you could reconfigure docker-compose.yml to use an AMD GPU or even just run purely on the CPU if you have an inordinate amount of patience. Note that I am running a humble RTX 3060.
* *Sybil said something weird, offensive, or inconsistent to me* - Really? [You don't say!](https://en.wikipedia.org/wiki/Sybil_(1976_film))
* *Sybil gave me horrible code* - Yeah, well frankly the only models I've played with that generate nontrivial code that is even remotely tolerable are `qwq` and `notux`. For technical tasks, you'll certainly have more success with those. Sybil is not intended to excel at technical tasks, but instead be better at actually carrying a complex conversation. Also, Sybil already uses a *lot* of RAM so including such enormous models is impractical on my hardware - but you can easily swap out the egghead model for `qwq` or `notux` if you have the hardware resources!
* *What's with the whole Catholic thing?* - First of all, [AI Is a Crapshoot](https://tvtropes.org/pmwiki/pmwiki.php/Main/AiIsACrapShoot). It is *always* possible to craft queries that can generate whatever edgy or offensive content you desire - even on highly "aligned" models. However, in order to get better results, Sybil does heavily utilize uncensored models. As a Catholic myself, I wanted to at least make a good faith effort to align Sybil with my values and reduce the probability of Sybil recommending or agreeing to immoral things. With that said, note that `herd_feels` and `herd_tasker` do not use uncensored models, and that `herd_collector` (which aggregates everything into a final output) is uncensored and simply told its a female cockatoo in cyberspace with multiple personality disorder. In effect, Sybil has morals but can "choose" (very much for lack of a better term) not to care about them when responding (as an aside, this is actually similar to the architecture of the Sonny robot in 2004's I Robot). Also note that this is a *prototype* and a *technology demonstrator* - there is ample room for improvement.
* *I don't like the personalities* - No problem! Sybil is open source, and can easily be reprogrammed with whatever collection of "personalities" on whatever spectrum of edginess you desire. With that obvious fact out of the way, I would respectfully ask that you don't do anything uncooth or gravely immoral. I can't control you though, you have free will!
* *Sybil crashed or hung* - Yeah, again its a prototype so just restart the pod and try again. It isn't actually alive or aware so don't feel too bad bro. Also, note that ollama has ongoing issues with models entering infinite inference loops and you may want to look into that. Implementing a timeout and retry mechanism would be prudent for a production system.
* *Sybil didn't really respond to me* - Then ask again! Sometimes, Sybil seems to "space out" and fall back to regurgitating one of the system prompts.
* *Why a cockatoo and not a llama?* - My wife likes cockatoos a lot more than llamas. It also references an inside joke about a hypothetical cockatoo between the two of us.

# License
Sybil's code is permissively licensed under the usual MIT License. Note that each ollama model has its own license.

# Models Used
