class cdh4::hadoop_client ($hadoop_namenode = "hdp") {
  class { 'cdh4': }

  package { 'hadoop-client':
    ensure => latest,
    require => File['cdh4_repo'],
  }

  file { '/etc/hadoop/conf/core-site.xml':
/*   Copyright (C) 2013-2014 Computer Sciences Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. */

    ensure => present,
    owner => root,
    group => root,
    mode => 0644,
    content => template('cdh4/hadoop/conf/core-site.xml.erb'),
    require => Package['hadoop-client']
  }
}
