# frozen_string_literal: true

#
# Environment and port
#
port ENV.fetch("HANAMI_PORT", 2300)
environment ENV.fetch("HANAMI_ENV", "development")

#
# Threads within each Puma/Ruby process (aka worker)
#

# Configure the minimum and maximum number of threads to use to answer requests.
max_threads_count = ENV.fetch("HANAMI_MAX_THREADS", 5)
min_threads_count = ENV.fetch("HANAMI_MIN_THREADS") { max_threads_count }

threads min_threads_count, max_threads_count

#
# Workers (aka Puma/Ruby processes)
#

puma_concurrency = Integer(ENV.fetch("HANAMI_WEB_CONCURRENCY", 0))
puma_cluster_mode = puma_concurrency > 1

# How many worker (Puma/Ruby) processes to run.
# Typically this is set to the number of available cores.
workers puma_concurrency

#
# Cluster mode (aka multiple workers)
#

if puma_cluster_mode
  # Preload the application before starting the workers. Only in cluster mode.
  preload_app!

  # Code to run immediately before master process forks workers (once on boot).
  #
  # These hooks can block if necessary to wait for background operations unknown
  # to puma to finish before the process terminates. This can be used to close
  # any connections to remote servers (database, redis, …) that were opened when
  # preloading the code.
  before_fork do
    Hanami.shutdown
  end
end
