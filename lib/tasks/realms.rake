require "./lib/tasks/blizz/wow-api.rb"

$LJUST = 40

namespace :realms do
  task :store_all, [:client_id, :client_secret, :verbosity] => :environment do |task, args|

    if args[:client_id].nil? || args[:client_secret].nil?
      puts "Usage: rake realms:fetch_all[<client_id>,<client_secret>]"
      exit 1
    end

    client_id = args[:client_id]
    client_secret = args[:client_secret]
    if !args[:verbosity].nil?
      verbosity = args[:verbosity].to_i
    else
      verbosity = 2
    end
    print "Getting access for us region...".ljust($LJUST) if verbosity > 0
    STDOUT.flush if verbosity > 0
    success = 0
    retried = 0
    to_retry = 0
    blz = WoWAPI.new(:us, client_id, client_secret) do |context, args|
      if verbosity > 1
        retried += 1 if context == :get_success && args[:retry_cnt] > 0
        success += 1 if context == :get_success
        to_retry += 1 if context == :get_error
        st = "#{success} (#{retried}/#{to_retry})".ljust(15)
        st += "#{context}".ljust(20)
        st += args[:message].ljust(40) if context == :get_error || context == :get_fatal
        st += "#{args[:uri]}".ljust(60)
        st += "#{args[:params][:namespace]} #{args[:params][:locale]}"
        puts st.blue if context == :get_before && verbosity > 3
        puts st.green if context == :get_success && verbosity > 3
        puts st.red if context == :get_error && verbosity > 2
        puts st.red.bold if context == :get_fatal && verbosity > 1
        puts st.green.bold if context == :get_success && args[:retry_cnt] > 0 && verbosity > 2

        puts "UNEXPECTED ERROR: #{args[:message]}".yellow if context == :unexpected_error && verbosity > 0

      end
    end
    puts " done" if verbosity > 0

    puts "Fetching all realms...".ljust($LJUST) if verbosity > 0
    to_store = {}
    realms = blz.realms()
    realms.each do |id, locales|
      to_store[id] = {
          blizz_id: id,
          slug: locales[:en_US][:slug],
          region: locales[:en_US][:region],
          status: locales[:en_US][:status],
          population: locales[:en_US][:population],
          category: locales[:en_US][:category],
          locale: locales[:en_US][:locale],
          timezone: locales[:en_US][:timezone],
          realm_type: locales[:en_US][:realm_type],
          realm_names: [RealmName.new(locale: :en_US, name: locales[:en_US][:name])]
        }
      locales.select{|k,v|k!=:en_US}.each do |locale, realm_data|
        to_store[id][:realm_names] << RealmName.new(locale: locale, name: realm_data[:name])
      end
    end

    print "Storing them in db...".ljust($LJUST) if verbosity > 0
    STDOUT.flush if verbosity > 0
    Realm.create(to_store.values)
    puts " done" if verbosity > 0

  end
end
