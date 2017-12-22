module CustomCups
  extend self
  @@_printers_file = {}

  def printer_name_for(value)
    show_destinations[value] || value
  end

  def show_destinations
    return { 'PDF' => 'PDF' } if ENV['TRAVIS']

    printers_file.split("\n").inject({}) do |memo, item|
      if item.start_with?('#')
        memo
      else
        _item, id, name = *item.match(/^(.+)\|(.+):rm/)
        memo.merge!({ id => name })
      end
    end
  end

  def printers_file
    if @@_printers_file[:time].to_i > 10.minutes.ago.to_i
      # cache
      return @@_printers_file[:file]
    end

    @@_printers_file[:time] = Time.zone.now.to_i
    @@_printers_file[:file] = `cat /etc/printcap`
  end

  def last_job_id(printer)
    all_jobs(printer).last || 1
  end

  def all_jobs(printer)
    keys = ::Cups.all_jobs(printer).keys
    if ENV['TRAVIS']
      p "All jobs"
      p keys
    end
    keys.sort
  end
end
