require "./lib/tasks/blizz/wow-api.rb"

namespace :items do
  task :store_all, [:region, :client_id, :client_secret, :verbosity] => :environment do |task, args|
    region = args[:region].to_sym
    client_id = args[:client_id]
    client_secret = args[:client_secret]
    if !args[:verbosity].nil?
      verbosity = args[:verbosity].to_i
    else
      verbosity = 2
    end

    print "Getting access for #{region.to_s} region...".ljust($LJUST) if verbosity > 0
    STDOUT.flush if verbosity > 0
    success = 0
    retried = 0
    to_retry = 0
    blz = WoWAPI.new(region, client_id, client_secret) do |context, args|
      retried += 1 if context == :get_success && args[:retry_cnt] > 0
      success += 1 if context == :get_success
      to_retry += 1 if context == :get_error
      if verbosity > 1
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

    puts "Fetching all items...".ljust($LJUST) if verbosity > 0
    to_store = {}
    items = blz.items()
    # puts items.inspect
    to_store = {}
    items.each do |id, locales|
      to_store[id] = {
        item_id: locales[:en_US][:id],
        quality: locales[:en_US][:quality],
        class_id: locales[:en_US][:class_id],
        subclass_id: locales[:en_US][:subclass_id],
        binding: locales[:en_US][:binding],
        version: locales[:en_US][:version],
        item_names: [ItemName.new(locale: :en_US, name: locales[:en_US][:name])]
      }
      locales.select{|k,v|k!=:en_US}.each do |locale, realm_data|
        to_store[id][:item_names] << ItemName.new(locale: locale, name: realm_data[:name])
      end
    end

    print "Storing them in db...".ljust($LJUST) if verbosity > 0
    STDOUT.flush if verbosity > 0
    # puts to_store.values.inspect
    Item.create(to_store.values)
    puts " done. #{success} requests issued. #{retried} had to be repeated" if verbosity > 0
  end
end
