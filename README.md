# -*- mode: org -*-
# -*- Coding: utf-8 -*-
#+STARTUP: overview indent inlineimages logdrawer
#+TITLE:       ScoreP usage on OpenMP programs
#+AUTHOR:      João V. F. Lima
#+LANGUAGE:    en
#+TAGS: 
#+OPTIONS:   H:3 num:t toc:t \n:nil @:t ::t |:t ^:t -:t f:t *:t <:t
#+OPTIONS:   TeX:t LaTeX:nil skip:nil d:nil todo:t pri:nil tags:not-in-toc
#+COLUMNS: %25ITEM %TODO %3PRIORITY %TAGS
#+SEQ_TODO: TODO(t!) STARTED(s!) WAITING(w@) APPT(a!) | DONE(d!) CANCELLED(c!) DEFERRED(f!)
#+LATEX_CLASS: article
#+LaTeX_CLASS_OPTIONS: [a4paper,11pt]
#+LATEX_HEADER: \usepackage{times}
#+LATEX_HEADER: \usepackage[margin=2cm]{geometry}

* Download and Compile Scorep

First download ScoreP from the website:
- [[http://www.vi-hps.org/projects/score-p/]]

Latest version from the site:
#+begin_src sh :results output :exports both
wget http://www.vi-hps.org/upload/packages/scorep/scorep-2.0.1.tar.gz
#+end_src

Compile in your system:
#+begin_src sh :results output :exports both
tar -xvzf scorep-2.0.1.tar.gz
cd scorep-2.0.1
mkdir build
cd build
./configure --prefix=$HOME/install/scorep-2.0.1/
make -j 4
make install
#+end_src

* Bash environemnt

Configure your environment with a =scorep.env= file:
#+BEGIN_EXAMPLE
SCOREP_HOME=$HOME/install/scorep-2.0.1
export PATH=$SCOREP_HOME/bin:$PATH
export C_INCLUDE_PATH=$SCOREP_HOME/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$SCOREP_HOME/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=$SCOREP_HOME/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$SCOREP_HOME/lib:$LD_LIBRARY_PATH
#+END_EXAMPLE

Then, execute this command at you terminal:
#+begin_src sh :results output :exports both
source scorep.env
#+end_src

* Compile and run

Example code with OpenMP:
#+begin_src C
/* History: Written by Tim Mattson, 11/99. */

#include <stdio.h>
#include <omp.h>

static long num_steps = 100000000;
double step;
int main() {
    int i;
    double x, pi, sum = 0.0;
    double start_time, run_time;

    step = 1.0 / (double)num_steps;
    for (i = 1; i <= 4; i++) {
        sum = 0.0;
        omp_set_num_threads(i);
        start_time = omp_get_wtime();
#pragma omp parallel
        {
#pragma omp single
            printf(" num_threads = %d", omp_get_num_threads());

#pragma omp for reduction(+ : sum)
            for (i = 1; i <= num_steps; i++) {
                x = (i - 0.5) * step;
                sum = sum + 4.0 / (1.0 + x * x);
            }
        }
        pi = step * sum;
        run_time = omp_get_wtime() - start_time;
        printf("\n pi is %f in %f seconds and %d threads\n", pi, run_time, i);
    }
}
#+end_src

Compile your OpenMP application with:
#+begin_src sh :results output :exports both
scorep --mpp=none --thread=omp:pomp_tpd --nocompiler --nocuda \
       --noonline-access --nopdt --nouser  --noopencl gcc -fopenmp \
       -o pi_loop pi_loop.c
#+end_src

Below, you can find the enviroment variables to collect traces. 
You can increase the value of =SCOREP_TOTAL_MEMORY= if needed.
#+begin_src sh :results output :exports both
export SCOREP_TOTAL_MEMORY=8MB
export SCOREP_ENABLE_TRACING=true
#+end_src

Run the program as usual:
#+begin_src sh :results output :exports both
./pi_loop
#+end_src

You should have a directory with a name similar to
=scorep-20160510_1417_2705760382923045= and a file inside named 
=traces.otf2=.

* Convert to Paje format

Convert to Paje Trace format with this script ([[https://raw.githubusercontent.com/schnorr/akypuera/master/src/otf2-omp-print/otf2ompprint2paje.pl][link HERE]]):
#+begin_src sh :results output :exports both
wget \
https://raw.githubusercontent.com/schnorr/akypuera/master/src/otf2-omp-print/otf2ompprint2paje.pl
perl ./otf2ompprint2paje.pl traces.otf2 > traces.paje
#+end_src

You can view a Paje trace using Paje or Vite (both have Debian packages):
- [[http://paje.sourceforge.net/]]
- [[http://vite.gforge.inria.fr/]]

In Paje you should see this trace. Note that I changed the colors of
each event using Paje.
A regular trace would have no colors.
#+caption: Paje trace from Pi computation.
[[./img/scorep-pi.png]]


* Lulesh							   :noexport:
#+begin_src sh :results output :exports both
grep ^State traces.csv|sed 's/^\(.*\)!$omp \([a-z ].*\)@lulesh.*$/\1\2/g' > clean-traces.csv
#+end_src

* EZtrace							   :noexport:

#+begin_src sh :results output :exports both
wget http://gforge.inria.fr/frs/download.php/file/35458/eztrace-1.1-2.tar.gz
sudo apt-get install binutils-dev libiberty-dev 
../configure --prefix=$HOME/install/eztrace --with-cuda=no
#+end_src

#+BEGIN_EXAMPLE
EZTRACE_HOME=$HOME/install/eztrace
export PATH=$EZTRACE_HOME/bin:$PATH
export C_INCLUDE_PATH=$EZTRACE_HOME/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$EZTRACE_HOME/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=$EZTRACE_HOME/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=$EZTRACE_HOME/lib:$LD_LIBRARY_PATH
#+END_EXAMPLE

* Spack								   :noexport:
Site: [[http://software.llnl.gov/spack/]]

Instalação dessa forma:
#+begin_src sh :results output :exports both
mkdir ~/install
cd ~/install
git clone https://github.com/llnl/spack.git
#+end_src

Adiciona essa linha no arquivo =~/.bashrc=:
#+BEGIN_EXAMPLE
. $HOME/install/spack/share/spack/setup-env.sh
#+END_EXAMPLE

* Scorep							   :noexport:
#+begin_src sh :results output :exports both
spack install scorep
#+end_src

* gem5								   :noexport:
#+BEGIN_EXAMPLE
git clone https://github.com/gem5/gem5.git
sudo apt-get install scons swig zlib1g-dev m4 python-dev build-essential g++
wget -b http://www.gem5.org/dist/current/arm/aarch-system-2014-10.tar.xz
cd gem5
scons build/ARM/gem5.opt -j 4
#+END_EXAMPLE
