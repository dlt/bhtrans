require "rubygems"
require "mechanize"
require "json"
require "pp"

class BHTransCrawler
  ROOT_URL = "http://servicosbhtrans.pbh.gov.br"
  BUSLINES_URL = ROOT_URL + "/bhtrans/servicos_eletronicos/transporte_itinerario_info.asp"
  BUSAGENDA_URL = ROOT_URL + "/bhtrans/servicos_eletronicos/transporte_qh_resultado.asp?linha=%s"

  AGENDA = Hash.new { |hash, key| hash[key] = [] }

  attr_reader :agent
  attr_reader :buslines_page

  def initialize
    @agent = Mechanize.new
  end


  def start
    puts "Starting to retrieve bus agendas"

    @buslines_page = agent.post(BUSLINES_URL)

    buslines.each do |number_node, name_node|
      number, name = number_node.text, name_node.text

      bus_identifier = "#{name} (#{number})"
      set_agenda_tables_for(bus_identifier, agent.get(busline_url(number)))
    end
  end


  def set_agenda_tables_for(bus_identifier, page)
    page.parser.css("div.diaUtil").map do |div|

      title_table, minutes_table = div.css("table")
      title = get_table_title(title_table)

      unless title.empty?
        puts "Retrieving agenda #{title} for bus #{bus_identifier}..."
        AGENDA[bus_identifier].push(:table_name => title, :agenda => minutes(minutes_table))
      end

    end
  end

  def get_table_title(title_table)
    title_table.text.strip.gsub(/\s+/, " ").strip
  end

  def minutes(table)
    minutes_tr = table.css("tr").last
    bus_leavings_minutes = minutes_tr.css("td")[1..-1]

    bus_leavings_table = {}

    0.upto(23).each do |hour|
      if leaving_minutes = bus_leavings_minutes[hour]
        bus_leavings_table[hour] = leaving_minutes.css("a").map { |a| a.text.to_i }
      end
    end

    bus_leavings_table
  end


  def buslines
    @buslines ||= begin
      table = buslines_page.parser.css("div.resultadoTabela table")[0]

      table.css("tr").map do |tr|
        tr.children.select { |node| node.is_a?(Nokogiri::XML::Element) }
      end[1..-1]
    end
  end

  def write_to_json
    puts "writing file to json..."
    File.open("agenda.json", "w") { |file| file.puts(AGENDA.to_json) }
  end

  def busline_url(bus_number)
    BUSAGENDA_URL % bus_number
  end
end

bhtrans_crawler = BHTransCrawler.new
bhtrans_crawler.start
bhtrans_crawler.write_to_json
