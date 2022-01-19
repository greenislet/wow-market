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
    items = blz.items((0..1000), [:fr_FR, :zh_CN])
    to_store = {}
    items.each do |id, locales|
      locale = locales.keys.first
      to_store[id] = {
        item_id: locales[locale][:id],
        quality: locales[locale][:quality],
        class_id: locales[locale][:class_id],
        subclass_id: locales[locale][:subclass_id],
        binding: locales[locale][:binding],
        version: locales[locale][:version],
        item_names: [ItemName.new(locale: locale, name: locales[locale][:name])]
      }
      locales.select{|k,v|k!=locale}.each do |locale, realm_data|
        to_store[id][:item_names] << ItemName.new(locale: locale, name: realm_data[:name])
      end
    end

    print "Storing them in db...".ljust($LJUST) if verbosity > 0
    STDOUT.flush if verbosity > 0
    Item.create(to_store.values)
    puts " done. #{success} requests issued. #{retried} had to be repeated" if verbosity > 0
  end
end
