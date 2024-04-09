# -*- mode: ruby -*-
# vim: set ft=ruby :

#ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

MACHINES = {
  :vmrpm => {
        :box_name => "centos/8",
		:vm_name => "vmrpm",
        #:ip_a ddr => '192.168.8.9',
		:box_version => "8",
		:net => [
           ["192.168.8.3", 2, "255.255.255.0", "mynet1"],
		#
        ],

				   

	}

		
  }


Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|
		config.vm.synced_folder "sync/", "/vagrant", type: "rsync", create: "true"
      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

		        boxconfig[:net].each do |ipconf|
        box.vm.network("private_network", ip: ipconf[0], adapter: ipconf[1], netmask: ipconf[2], virtualbox__intnet: ipconf[3])

      end
		  

          box.vm.provider :virtualbox do |vb|
            	  vb.customize ["modifyvm", :id, "--memory", "1024"]
				  vb.name = boxconfig[:vm_name]
         
                  end
          

		box.vm.provision "shell", path: "update.sh", name: "update"
		#box.vm.provision "shell", path: "assembly.sh", name: "dz"
		#box.vm.provision "shell", path: "dz_lvm.sh", name: "dz1"
end
      end

end
