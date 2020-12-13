class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  has_one :profile, :dependent => :destroy


  has_many :notifications#, :dependent => :destroy# Notifications generated by user (not genreted for users)
  has_one :notification_setting
  has_many :devices

  has_many :participations
  has_many :uploads
  
  #after_create :assign_default_role
  before_create :assign_uuid
  

  def assign_uuid
    self.uuid = SecureRandom.uuid
  end


  def assign_default_role
    default_roles = Role.where(default_role: true)
    for default_role in default_roles
      self.assign(default_role.id)
    end
  end

  def assign(role_id)
    self.assignments = [] if self.assignments.blank?
    self.assignments << role_id
    self.save
  end

  def roles
    roles = []
    for assignment in  self.assignments
      role = Role.find_by_id(assignment)
      self.current_role_id == assignment ? current = true : current = false
      roles <<   {title: role.title, id: role.id, current: current} if !role.blank?
    end
    return roles
  end

  def unassign(role_id)
    self.assignments -= [role_id] if !self.assignments.blank?
    if self.current_role_id == role_id
      self.current_role_id = nil
    end
    self.save
    self.assign_available_role
  end

  def selected_role
    self.assign_available_role
    Role.find_by_id(self.current_role_id)
  end

  def assign_available_role
    if self.current_role_id.blank?
      self.current_role_id = self.assignments[0] if !self.assignments.blank? && self.assignments[0] 
      self.save
    end
  end

  def ability
    self.selected_role.ability if self.selected_role
  end

  def has_ability(ab)
    flag = false
    if !self.selected_role.blank? && !self.selected_role.ability.blank?
      for a in self.selected_role.ability
        flag = true if a['title'] == ab
      end
    end
    return flag
  end

  def notify_user
    code = rand(10 ** 6).to_s.rjust(6,'0')  
    self.last_code = code
    self.last_code_datetime = DateTime.now
    self.last_login = DateTime.now
    self.save
    VerificationsMailer.notify_email(self.id, code).deliver_later
  end

  def self.verify(code)
    user = self.where('last_code = ? AND last_code_datetime > ?', code, 10.minutes.ago).first
  end
  
end
