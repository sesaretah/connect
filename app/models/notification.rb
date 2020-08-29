class Notification < ApplicationRecord
    # belongs_to :notifiable, :polymorphic => true
    # #belongs_to :user
    # after_create :notify_by_mail

    # def self.seen_list(notifications)
    #     for notification in notifications
    #         notification.seen = true
    #         notification.save
    #     end
    #     return true
    # end

    # def notify_by_mail
    #     for target_user_id in self.target_user_ids
    #         NotificationsMailer.notify_email(target_user_id, self.notification_type, self.user.profile.fullname, self.notifiable.title).deliver_later
    #     end
    # end

    # def user
    #     User.find_by_id(self.source_user_id) if self.source_user_id
    # end

    include ActionView::Helpers::TextHelper
    belongs_to :notifiable, :polymorphic => true
    #belongs_to :user
    after_create :notify_by_fcm
    after_create :notify_by_mail
    

    def self.seen_list(notifications)
        for notification in notifications
            notification.seen = true
            notification.save
        end
        return true
    end

    def notify_by_mail
        for target_user_id in self.target_user_ids.uniq
            p '!!!!!!!!!!!!!!!!'
            p target_user_id
            p Notification.notification_type_eql(self.notification_type, self.notifiable.class.name)
            if NotificationSetting.check(target_user_id, Notification.notification_type_eql(self.notification_type, self.notifiable.class.name),'email')
                NotificationsMailer.notify_email(target_user_id, self.notification_type, self.user.profile.fullname, self.notifiable.title, self.custom_text).deliver_later
            end
        end
    end


    def notify_by_fcm
        for target_user_id in self.target_user_ids.uniq
            if NotificationSetting.check(target_user_id, Notification.notification_type_eql(self.notification_type, self.notifiable.class.name),'push')
                target_user = User.find_by_id(target_user_id)
                token = target_user.devices.last.token if target_user && target_user.devices && target_user.devices.last
                fcm_text = fcm_text(target_user_id, self.notification_type, self.user.profile.fullname, self.notifiable.title, self.custom_text)
                FcmJob.perform_later(fcm_text[:title], fcm_text[:body], token) if token
            end
        end
    end

    def fcm_text(user_id, notify_type, notifier, notify_text, custom_text, auxiliary_custom_text=nil)
        case notify_type
        when  'Like'
            title = "#{I18n.t(:like_notification)} #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}"
            body =  "#{truncate(custom_text)}"
        when  'Share'
            title = "#{I18n.t(:share_notification)}  #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}" 
            body =  "#{truncate(custom_text)}"
        when  'Follow'
            title = "#{I18n.t(:follow_notification)}  #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}" 
            body =  "#{truncate(custom_text)}"
        when  'Bookmark'
            title = "#{I18n.t(:bookmark_notification)}  #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}" 
            body =  "#{truncate(custom_text)}"
        when  'Comment'
            title = "#{I18n.t(:comment_notification)}  #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}" 
            body =  "#{truncate(custom_text)}"
        when  'Post'
            title = "#{I18n.t(:post_notification)}  #{I18n.t(:via)} #{notifier} #{I18n.t(:onto)} #{notify_text}" 
            body =  "#{truncate(custom_text)}"
        end
        return {title: title, body: body}
    end


    def self.notification_type_eql(type, model)
        return 'add_likes_to_'+ model.downcase.pluralize+'_' if  type == 'Like'
        return 'add_shares_to_'+ model.downcase.pluralize+'_' if  type == 'Share'
        return 'add_follows_to_'+ model.downcase.pluralize+'_' if  type == 'Follow'
        return 'add_bookmarks_to_'+ model.downcase.pluralize+'_' if  type == 'Bookmark'
        return 'add_comment_to_'+ model.downcase.pluralize+'_' if  type == 'Comment'
        return 'add_post_to_'+ model.downcase.pluralize+'_' if  type == 'Post'

    end

    def user
        User.find_by_id(self.source_user_id) if self.source_user_id
    end

    def self.user_related(user, page)
        self.where("source_user_id != #{user.id} AND target_user_hash ->> '#{user.id}' = 'true'")
    end
end
