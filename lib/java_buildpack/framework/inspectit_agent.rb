# Cloud Foundry Java Buildpack
#
# Copyright 2013-2017 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'
require 'java_buildpack/util/qualify_path'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch inspectIT support.
    class InspectitAgent < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Util

      def initialize(context)
        context[:configuration]['version'] = context[:application].services.find_service(FILTER)['credentials']['version'] if context[:application].services.one_service? FILTER, 'cmr_host', 'version'
        super(context)
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_zip
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        credentials = @application.services.find_service(FILTER)['credentials']

        @droplet.java_opts
                .add_javaagent(agent)
                .add_system_property('inspectit.agent.name', application_name)
                .add_system_property('inspectit.repository', credentials['cmr_host'])
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, 'cmr_host', 'version'
      end

      private

      FILTER = /inspectit/

      private_constant :FILTER

      def agent
        @droplet.sandbox + 'inspectit-agent.jar'
      end

      def application_name
        @configuration['application_name'] || @application.details['application_name']
      end

    end

  end
end
