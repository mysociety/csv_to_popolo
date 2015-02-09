require 'csv_to_popolo/version'
require 'csv'

VERSION = "0.0.1"

class Popolo
  class CSV
    
    def initialize(file)
      @file = file
      @csv_args = { :headers => true }
    end

    def data
      ::CSV.table(@file, @csv_args).map { |r| popolo_for(r) }
    end

    private 
    def popolo_for(r)
      as_is = [
        :id, :name, :family_name, :given_name, :additional_name, 
        :honorific_prefix, :honorific_suffix, :patronymic_name, :sort_name,
        :email, :gender, :birth_date, :death_date, :image, :summary,
        :biography, :national_identity
      ]

      popolo = {}
      as_is.each do |sym|
        popolo[sym] = r[sym] if r.has_key? sym
      end

      popolo[:memberships] = [
        {
          organization: { 
            name: r[:faction],
          },
          area: { 
            name: r[:area],
          },
        }
      ]

      return popolo

    end

  end

end
