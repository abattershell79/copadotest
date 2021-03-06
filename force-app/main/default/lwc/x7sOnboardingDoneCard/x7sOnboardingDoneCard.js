/*
 *   Copyright (c) 2020. 7Summits Inc.
 */

import { LightningElement, api } from 'lwc';

export default class X7sOnboardingDoneCard extends LightningElement {

    @api label;
    @api icon;
    @api link;
    @api description;
    @api openInNewWindow = false;

    get urlTarget() {
        return this.openInNewWindow ? '_blank' : '_self';
    }

    handleClick() {

        const linkClickEvent = new CustomEvent ('linkclick', {
            detail: {
                        url : this.link
                    }
        });
        this.dispatchEvent(linkClickEvent);

    }
}