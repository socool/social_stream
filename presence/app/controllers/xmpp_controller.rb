require 'xmpp4r'
require 'xmpp4r/muc'
require 'xmpp4r/roster'
require 'xmpp4r/client'
require 'xmpp4r/message'

class XmppController < ApplicationController
  
  #Mapping XMPP Standar Status to Social Stream Chat Status
  STATUS = {
  '' => 'available', 
  'chat' => 'available', 
  'away' => 'away', 
  'xa' => 'away',
  'dnd' => 'dnd',
  #Special status to disable chat
  'disable' => 'disable'
  }
   
   
  #API METHODS

  def resetConnection
    unless authorization
      render :text => "Authorization error"
      return
    end
    
    users = User.find_all_by_connected(true)
    
    users.each do |user|
      user.connected = false
      user.save!
    end
    
    render :text => "Ok" 
  end


  def unsetConecction
    unless authorization
      render :text => "Authorization error"
      return
    end
    
    user = User.find_by_slug(params[:name])
    
    if user && user.connected
       user.connected = false
       user.save!
       render :text => "Ok"
       return
    end
    
    render :text => "Error"
  end
  
  
  def setConnection  
    unless authorization
      render :text => "Authorization error"
      return
    end
    
    user = User.find_by_slug(params[:name])
    
    if user && !user.connected
       user.connected = true
       user.status = "available"
       user.save!
       render :text => "Ok"
       return
    end
    
    render :text => "Error"
  end
  
  
  def synchronizePresence  
    unless authorization
      render :text => "Authorization error"
      return
    end
     
    #Actual connected users
    user_slugs = params[:name]
    
    #Check connected users
    users = User.find_all_by_connected(true)
    
    users.each do |user|
      if user_slugs.include?(user.slug) == false
        user.connected = false
        user.save!
      end
    end
    
    user_slugs.each do |user_slug|
      u = User.find_by_slug(user_slug)
      if (u != nil && u.connected  == false)
        u.connected = true
        u.save!
      end
    end
    
    render :text => "ok"
  end
  
  
  def setPresence  
    unless authorization
      render :text => "Authorization error"
      return
    end
    
    user = User.find_by_slug(params[:name])
    status = params[:status]
    
    if setStatus(user,status)
      render :text => 'Status changed'
    else
      render :text => 'Status not changed'
    end
    
  end
  
  
  def unsetPresence  
    unless authorization
      render :text => "Authorization error"
      return
    end
    render :text => "Ok"
  end
 
  def authorization
    return params[:password] == SocialStream::Presence.xmpp_server_password
  end
  
  
  def chatWindow
    if (current_user.connected) and (current_user.status != 'disable') and (params[:userConnected]=="true")
      render :partial => 'xmpp/chat_contacts'
    else
      #User not connected or chat desactivated
      render :partial => 'xmpp/chat_off'
    end 
  end
  
  

 
  
  #TEST METHODS
  def active_users
    @users = User.find_all_by_connected(true)
    @all_users = User.all
  end
   
  def test
    puts "TEST"
      
    #XMPP DOMAIN
    domain = SocialStream::Presence.domain
    #PASSWORD
    password= SocialStream::Presence.password
    #SS Username
    ss_name = SocialStream::Presence.social_stream_presence_username
            
    ss_sid = ss_name + "@" + domain 
    client = Jabber::Client.new(Jabber::JID.new(ss_sid))
    client.connect
    client.auth(password)
   
    #Sending a message
    msg = Jabber::Message::new(ss_sid, "Message&order")
    msg.type=:chat
    client.send(msg) 
    client.close()
  end
  
  
  
  private
  
  def setStatus(user,status)
    if user and status and user.status != status and validStatus(status)  
      user.status = STATUS[status]
      user.save!
      return true
    end
    return false
  end 
  
  def validStatus(status)
    return STATUS.keys.include?(status)
  end
  
end