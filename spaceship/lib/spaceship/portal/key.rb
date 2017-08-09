module Spaceship
  module Portal
    class Key < PortalBase
      ##
      # data model for managing JWT tokens or "Keys" as the ADP refers to them

      APNS_ID = 'U27F4V844T'
      DEVICE_CHECK_ID = 'DQ8HTZ7739'
      MUSIC_KIT_ID = '6A7HVUVQ3M'

      attr_accessor :id
      attr_accessor :name

      attr_mapping({
        'keyId' => :id,
        'keyName' => :name,
        'services' => :services,
        'canDownload' => :can_download,
        'canRevoke' => :can_revoke
      })

      def self.all
        keys = client.list_keys
        keys.map do |key|
          new(key)
        end
      end

      def self.find(id)
        key = client.get_key(id: id)
        new(key)
      end

      ##
      # Creates a new JWT / Key for making requests to services.
      #
      # @param name [String] the name of the key
      # @param apns [Bool] whether the key should be able to make APNs requests
      # @param device_check [Bool] whether the key should be able to make DeviceCheck requests
      # @param music_id [String] the Music Id id (the autogenerated id, not the user specified identifier "music.com.etc...")
      def self.create(name: nil, apns: nil, device_check: nil, music_id: nil)
        service_config = {}
        service_config[APNS_ID] = [] if apns
        service_config[DEVICE_CHECK_ID] = [] if device_check
        service_config[MUSIC_KIT_ID] = [music_id] if music_id

        key = client.create_key!(name: name, service_configs: service_config)
        new(key)
      end

      def revoke!
        client.revoke_key!(id: id)
      end

      def download
        client.download_key(id: id)
      end

      def services
        raw_data['services'] || reload
        super
      end

      def service_configs_for(service_id)
        if (service = find_service(service_id))
          service['configurations']
        end
      end

      def has_apns?
        has_service?(APNS_ID)
      end

      def has_music_kit?
        has_service?(MUSIC_KIT_ID)
      end

      def has_device_check?
        has_service?(DEVICE_CHECK_ID)
      end

      def reload
        self.raw_data = self.class.find(id).raw_data
      end

      private

      def find_service(service_id)
        services.find do |service|
          service['id'] == service_id
        end
      end

      def has_service?(service_id)
        find_service(service_id) != nil
      end
    end
  end
end