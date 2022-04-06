import { FirebaseMessagingService } from "@aginix/nestjs-firebase-admin";
import { Injectable } from "@nestjs/common";
import { DriverEntity } from "../../entities/driver.entity";
import { OrderMessageEntity } from "../../entities/request-message.entity";

@Injectable()
export class DriverNotificationService {
    constructor(
        private firebaseMessaging: FirebaseMessagingService
    ) { }

    requests(driver: DriverEntity[]) {
        const tokens: string[] = driver.filter(_driver => _driver.notificationPlayerId != undefined).map(x => x.notificationPlayerId) as unknown as string[];
        this.firebaseMessaging.messaging.sendMulticast({
            tokens: tokens,
            android: {
                notification: {
                    sound: process.env.REQUEST_SOUND ?? 'default',
                    titleLocKey: 'notification_new_request_title',
                    bodyLocKey: 'notification_new_request_body',
                    channelId: 'request',
                    icon: 'notification_icon',
                    priority: 'high'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: process.env.REQUEST_SOUND ?? 'default',
                        badge: 1,
                        contentAvailable: true,
                        alert: {
                            titleLocKey: 'notification_new_request_title',
                            subtitleLocKey: 'notification_new_request_body'
                        }
                    }
                },
                headers: {
                    "apns-push-type": "background",
                    "apns-priority": "5",
                    "apns-topic": "io.flutter.plugins.firebase.messaging",
                }
            }
        });
    }

    canceled(driver: DriverEntity) {
        if(driver.notificationPlayerId == null) return;
        this.firebaseMessaging.messaging.send({
            token: driver.notificationPlayerId,
            android: {
                notification: {
                    sound: 'default',
                    titleLocKey: 'notification_cancel_title',
                    bodyLocKey: 'notification_cancel_body',
                    channelId: 'tripEvents',
                    icon: 'notification_icon'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        alert: {
                            titleLocKey: 'notification_cancel_title',
                            subtitleLocKey: 'notification_cancel_body'
                        }
                    }
                }
            }
        });
    }

    message(driver: DriverEntity, message: OrderMessageEntity) {
        this.firebaseMessaging.messaging.send({
            token: driver.notificationPlayerId ?? '',
            android: {
                notification: {
                    sound: 'default',
                    titleLocKey: 'notification_new_message_title',
                    bodyLocKey: message.content,
                    channelId: 'message',
                    icon: 'notification_icon'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        contentAvailable: true,
                        alert: {
                            titleLocKey: 'notification_new_message_title',
                            subtitle: message.content
                        }
                    }
                }
            }
        });
    }

    paid(driver: DriverEntity) {
        this.firebaseMessaging.messaging.send({
            token: driver.notificationPlayerId ?? '',
            android: {
                notification: {
                    sound: 'default',
                    titleLocKey: 'notification_paid_title',
                    bodyLocKey: 'notification_paid_body',
                    channelId: 'tripEvents',
                    icon: 'notification_icon'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        alert: {
                            titleLocKey: 'notification_paid_title',
                            subtitleLocKey: 'notification_paid_body',
                        }
                    }
                }
            }
        });
    }


}