require 'csv_to_popolo/version'
require 'csv'
require 'securerandom'

class Popolo
  class CSV

    @@opts = { 
      headers:           true,
      header_converters: :symbol 
    }
    
    def initialize(csv)
      raise "Need a CSV table, not a #{csv.class}" unless csv.class.name == 'CSV::Table'
      # Make sure every row has an ID. NB: CSV::Table has no map! method
      @csv = csv.map do |r| 
        r[:id] ||= "person/#{SecureRandom.uuid}" 
        r
      end
    end

    def self.from_file(file)
      new ::CSV.read(file, @@opts)
    end

    def self.from_data(data)
      new ::CSV.parse(data, @@opts)
    end

    def data
      @data ||= {
        persons:       persons,
        organizations: organizations,
        memberships:   memberships,
      }
    end

    def persons
      @csv.map { |r| Person.new(r).as_popolo }
    end

    def organizations
      parties + legislatures + executive
    end

    def memberships 
      party_memberships + legislative_memberships + executive_memberships
    end

    def parties 
      @_parties ||= @csv.find_all { |r| r.has_key? :group }.uniq { |r| r[:group] }.map do |r| 
        {
          id: r[:group_id] || "party/#{SecureRandom.uuid}",
          name: r[:group],
          classification: 'party',
        }
      end
    end

    # For now, assume that we always have a legislature
    # TODO cope with a file that *only* lists executive posts
    def legislatures
      [{
        id: 'legislature',
        name: 'Legislature', 
        classification: 'legislature',
      }]
    end

    def executive
      [{
        id: 'executive',
        name: 'Executive', 
        classification: 'executive',
      }]
    end

    def party_memberships 
      @_pmems ||= @csv.find_all { |r| r.has_key? :group }.map do |r|
        { 
          person_id: r[:id],
          organization_id: r[:group_id] || find_party_id(r[:group]),
          role: 'party representative',
          start_date: r[:start_date],
          end_date: r[:end_date],
        }.select { |_, v| !v.nil? } 
      end
    end

    def legislative_memberships 
      @_lmems ||= @csv.find_all { |r| r.has_key? :group }.map do |r|
        mem = { 
          person_id:        r[:id],
          organization_id:  'legislature',
          role:             'representative',
        }
        mem[:area] = { name: r[:area] } if r.has_key? :area and !r[:area].nil?
        mem
      end
    end

    def executive_memberships 
      @_emems ||= @csv.find_all { |r| r.has_key? :executive and !r[:executive].nil? }.map do |r|
        { 
          person_id:        r[:id],
          organization_id:  'executive',
          role:             r[:executive],
        }
      end
    end


    private

    def find_party_id(name)
      (parties.find { |p| p[:name] == name } or return)[:id]
    end


  end

  class Person

    def initialize(row)
      @r = row
    end

    def given?(key)
      @r.has_key? key and not @r[key].nil?
    end

    def contact_details
      return unless given? :twitter
      twitter = { 
        type: 'twitter',
        value: @r[:twitter],
      }
      return [ twitter ]
    end

    def as_popolo
      as_is = [
        :id, :name, :family_name, :given_name, :additional_name, 
        :honorific_prefix, :honorific_suffix, :patronymic_name, :sort_name,
        :email, :gender, :birth_date, :death_date, :image, :summary,
        :biography, :national_identity
      ]

      remap = { 
        first_name: :given_name,
        last_name: :family_name,
        organization: :group,
        organisation: :group,
      }

      remap.each { |old, new| @r[new] ||= @r[old] if given? old }

      popolo = {}
      as_is.each do |sym|
        popolo[sym] = @r[sym] if given? sym
      end

      popolo[:contact_details] = contact_details

      if given? :other_name
        popolo[:other_names] = [{ name: @r[:other_name] }]
      end

      return popolo.select { |_, v| !v.nil? } 

    end

  end

end
